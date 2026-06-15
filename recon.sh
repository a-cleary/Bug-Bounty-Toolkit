#!/usr/bin/env bash

set -eou pipefail

#################
# Configuration #
#################
BASE_DIR="$(pwd)"
TOOLS_DIR="${HOME}/Tools"

SCOPE_DIR="${BASE_DIR}/scope"
DISCOVERY_DIR="${BASE_DIR}/discovery"
CONTENT_DIR="${BASE_DIR}/content"
REPOS_DIR="${BASE_DIR}/repos"
ENRICHMENT_DIR="${BASE_DIR}/enrichment"
SCREENSHOT_DIR="${ENRICHMENT_DIR}/screenshots"
FINDINGS_DIR="${BASE_DIR}/findings"

WILDCARD_DOMAINS="${SCOPE_DIR}/wildcard_domains.txt"
KNOWN_SUBDOMAINS="${SCOPE_DIR}/known_subdomains.txt"
OUT_OF_SCOPE="${SCOPE_DIR}/out_of_scope.txt"

ENUM_RESULTS="${DISCOVERY_DIR}/enum_results.txt"
RAW_SUBDOMAINS="${DISCOVERY_DIR}/subdomains_raw.txt"
FINAL_SUBDOMAINS="${DISCOVERY_DIR}/subdomains.txt"

LIVE_HOSTS="${DISCOVERY_DIR}/live_hosts.txt"
HTTPX_JSON="${DISCOVERY_DIR}/live_hosts.json"

GAU_RESULTS="${CONTENT_DIR}/gau.txt"
WAYBACK_RESULTS="${CONTENT_DIR}/waybackurls.txt"
HISTORICAL_URLS="${CONTENT_DIR}/historical_urls.txt"

KATANA_URLS="${CONTENT_DIR}/katana_urls.txt"
ALL_URLS="${CONTENT_DIR}/all_urls.txt"

PARAMS="${CONTENT_DIR}/params.txt"

XSS_CANDIDATES="${CONTENT_DIR}/xss_candidates.txt"
SQLI_CANDIDATES="${CONTENT_DIR}/sqli_candidates.txt"
SSRF_CANDIDATES="${CONTENT_DIR}/ssrf_candidates.txt"
REDIRECT_CANDIDATES="${CONTENT_DIR}/redirect_candidates.txt"

JS_FILES="${CONTENT_DIR}/js_files.txt"

JS_ENDPOINTS="${CONTENT_DIR}/js_endpoints.txt"
JS_SECRETS="${CONTENT_DIR}/js_secrets.txt"

LINKFINDER_RAW="${CONTENT_DIR}/linkfinder_raw.txt"
SECRETFINDER_RAW="${CONTENT_DIR}/secretfinder_raw.txt"

EXPANDED_URLS="${CONTENT_DIR}/expanded_urls.txt"

GIT_CANDIDATES="${CONTENT_DIR}/git_candidates.txt"
GIT_REPOS="${CONTENT_DIR}/git_repos.txt"
GIT_SECRETS="${CONTENT_DIR}/git_secrets.txt"

TECH_JSON="${ENRICHMENT_DIR}/technologies.json"
WAF_JSON="${ENRICHMENT_DIR}/waf.json"

NUCLEI_RESULTS="${FINDINGS_DIR}/nuclei.jsonl"
WORDPRESS_HOSTS="${FINDINGS_DIR}/wordpress.txt"
JOOMLA_HOSTS="${FINDINGS_DIR}/joomla.txt"
GRAPHQL_HOSTS="${FINDINGS_DIR}/graphql.txt"
EXPOSED_PANELS="${FINDINGS_DIR}/exposed_panels.txt"

MAX_PARALLEL_DOMAINS=5

LINKFINDER="${TOOLS_DIR}/LinkFinder/linkfinder.py"
SECRETFINDER="${TOOLS_DIR}/SecretFinder/SecretFinder.py"
GIT_DUMPER="${TOOLS_DIR}/git-dumper/git_dumper.py"

mkdir -p "$DISCOVERY_DIR"
mkdir -p "$REPOS_DIR"
mkdir -p "$ENRICHMENT_DIR"
mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$FINDINGS_DIR"


###########
# Logging #
###########
info() {
    printf '[*] %s\n' "$1"
}

success() {
    printf '[+] %s\n' "$1"
}

error() {
    printf '[-] %s\n' "$1"
}


###################
# Tool Validation #
###################
check_binaries() {
    local binaries=(
        subfinder
        assetfinder
        amass
        httpx
        jq
        curl
        gau
        waybackurls
        katana
        unfurl
        gf
        #gitjacker
        trufflehog
        whatweb
        wafw00f
        gowitness
        nuclei
    )

    for binary in "${binaries[@]}"
    do 
        if ! command -v  "$binary" >/dev/null 2>&1
        then
            error "${binary} not installed"
            exit 1
        fi 
    done 
}

check_repositories() {

    local repos=(
        "$LINKFINDER"
        "$SECRETFINDER"
        "$GIT_DUMPER"
    )

    for repo in "${repos[@]}"; do
        [[ -f "$repo" ]] || {
            error "$repo not found"
            exit 1
        }
    done
}


####################
# Scope Validation #
####################
normalize_scope_files() {
    info "Normalizing scope files"
    for file in "$WILDCARD_DOMAINS", "$KNOWN_SUBDOMAINS", "$OUT_OF_SCOPE"
    do
        [[ ! -f "$file" ]] && continue
        grep -v '^#' "$file" | sed '/^\s*$/d' | tr '[:upper:]' '[:lower:]' | sort > "${file}.tmp"
        mv "${file}.tmp" "$file"
    done 
    success "Scope files normalized"
}


################
#  Enumeration #
################
enumerate_domain() {
    local domain="$1"

    local tmpdir
    tmpdir="$(mktemp -d)"

    subfinder -d "$domain" -all -silent > "${tmpdir}/subfinder.txt" 2>/dev/null &
    assetfinder --subs-only "$domain" > "${tmpdir}/assetfinder.txt" 2>/dev/null &
    amass enum -d "$domain" > "${tmpdir}/amass.txt" 2>/dev/null &
    (
        curl -s "https://crt.sh/?q=%25.${domain}&output=json" | 
        jq -r '.[].name_value' 2>/dev/null |
        tr '\r' '\n' |
        sed 's/\*\.//g' |
        sort -u
    ) > "${tmpdir}/crtsh.txt" &

    wait
    cat "$tmpdir"/*.txt 2>/dev/null | sort -u
    rm -rf "$tmpdir"
}
export -f enumerate_domain

enumerate_subdomains() {
    info "Starting passive enumeration"
    : > "$ENUM_RESULTS"
    xargs -a "$WILDCARD_DOMAINS" -P "$MAX_PARALLEL_DOMAINS" -I{} bash -c 'enumerate_domain "$@"' _ {} >> "$ENUM_RESULTS"
    sort -u "$ENUM_RESULTS" -o "$ENUM_RESULTS"
    success "$(wc -l < "$ENUM_RESULTS") subdomains discovered"
}


###################
# Scope Filtering #
###################
is_out_of_scope() {
    local host="$1"
    while read -r pattern
    do 
        [[ -z "$pattern" ]] && continue
        if [[ "$pattern" == \*.* ]]
        then 
            local regex
            regex=$(printf '%s\n' "$pattern" | sed 's/\./\\./g' | sed 's/\*/.*/g')
            [[ "$host" =~ ^${regex}$ ]] && return 0
        else
            [[ "$host" == "$pattern" ]] && return 0
        fi
    done  < "$OUT_OF_SCOPE"
    return 1
}

build_scope() {
    info "Building final scope"
    cat "$ENUM_RESULTS" "$KNOWN_SUBDOMAINS" | sort -u > "$RAW_SUBDOMAINS"
    : > "$FINAL_SUBDOMAINS"
    while read -r host;
    do 
        [[ -z "$host" ]] && continue 
        if ! is_out_of_scope "$host"
        then 
            echo "$host" >> "$FINAL_SUBDOMAINS"
        fi 
    done < "$RAW_SUBDOMAINS"
    success "$(wc -l < "$FINAL_SUBDOMAINS") hosts in scope"
}


########################
# Live Host Validation #
########################
validate_hosts() {
    info "Validating live hosts"
    httpx -l "$FINAL_SUBDOMAINS" -json -silent -title -tech-detect -status-code -follow-redirects > "$HTTPX_JSON"
    jq -r '.url' "$HTTPX_JSON" > "$LIVE_HOSTS"
    success "$(wc -l < "$LIVE_HOSTS") live hosts found"
}


#######################
# Historical Analysis #
#######################
collect_historical_urls() {
    info "Collecting historical URLs"
    gau --threads 20 < "$LIVE_HOSTS" > "$GAU_RESULTS" &
    waybackurls < "$LIVE_HOSTS" > "$WAYBACK_RESULTS" &

    wait
    cat "$GAU_RESULTS" "$WAYBACK_RESULTS" | sed '/^\s*$/d' | sort -u > "$HISTORICAL_URLS"
    success "$(wc -l < "$HISTORICAL_URLS") historical URLs collected"
}


#######################
# Live URL Collection #
#######################
collect_live_urls() {
    info "Running katana"
    katana -list "$LIVE_HOSTS" -silent -jc -kf > "$KATANA_URLS"
    success "$(wc -l < "$KATANA_URLS") URLs discovered via crawling"
}


################
# URL Analysis #
################
build_url_inventory() {
    info "Building URL inventory"
    cat "$HISTORICAL_URLS" "$KATANA_URLS" | sed '/^\s*$/d' | sort -u > "$ALL_URLS"
    success "$(wc -l < "$ALL_URLS") unique URLs"
}

extract_parameters() {
    info "Extracting parameter names"
    unfurl keys < "$ALL_URLS" | sort -u > "$PARAMS"
    success "$(wc -l < "$PARAMS") unique parameters"
}

generate_candidates() {
    info "Generating candidate URLs"
    gf xss < "$ALL_URLS" > "$XSS_CANDIDATES" || true
    gf sqli < "$ALL_URLS" > "$SQLI_CANDIDATES" || true
    gf ssrf < "$ALL_URLS" > "$SSRF_CANDIDATES" || true
    gf redirect < "$ALL_URLS" > "$REDIRECT_CANDIDATES" || true
    success "Candidate generation complete"
}


#######################
# JavaScript Analysis #
#######################
extract_javascript() {
    info "Extracting JavaScript URLs"
    grep -Ei '\.js([?#].*)?$' "$ALL_URLS" | sort -u > "$JS_FILES"
    success "$(count_lines "$JS_FILES") JavaScript files found"
}

run_linkfinder() {
    info "Running LinkFinder"
    : > "$LINKFINDER_RAW"
    cat "$JS_FILES" | xargs -P "$MAX_JS_WORKERS" -I{} python3 "$LINKFINDER" -i "{}" -o cli 2>/dev/null >> "$LINKFINDER_RAW"
    sort -u "$LINKFINDER_RAW" > "$JS_ENDPOINTS"
    success "$(count_lines "$JS_ENDPOINTS") endpoints discovered"
}

run_secretfinder() {
    info "Running SecretFinder"
    : > "$SECRETFINDER_RAW"
    cat "$JS_FILES" | xargs -P "$MAX_JS_WORKERS" -I{} python3 "$SECRETFINDER" -i "{}" -o cli 2>/dev/null >> "$SECRETFINDER_RAW"
    sort -u "$SECRETFINDER_RAW" > "$JS_SECRETS"
    success "$(count_lines "$JS_SECRETS") potential secrets identified"
}

normalize_js_endpoints() {
    info "Normalizing endpoints"
    grep -E '^(/|https?://)' "$JS_ENDPOINTS" | sort -u > "${JS_ENDPOINTS}.tmp"
    mv "${JS_ENDPOINTS}.tmp" "$JS_ENDPOINTS"
    success "$(count_lines "$JS_ENDPOINTS") normalized endpoints"
}

merge_discovered_endpoints() {
    info "Building expanded URL inventory"
    cat "$ALL_URLS" "$JS_ENDPOINTS" | sed '/^\s*$/d' | sort -u > "$EXPANDED_URLS"
    success "$(count_lines "$EXPANDED_URLS") total URLs"
}

javascript_analysis() {
    extract_javascript
    run_linkfinder
    normalize_js_endpoints
    run_secretfinder
    merge_discovered_endpoints
}


################
# Git Analysis #
################
find_git_repositories() {
    info "Checking for exposed Git repositories"
    grep -E '^https?://' "$EXPANDED_URLS" | sed 's#/$##' | sort -u | xargs -P 20 -I{} sh -c 'curl -sk "{}"/.git/HEAD | grep -q "refs/heads" && echo "{}"' > "$GIT_CANDIDATES"
    success "$(count_lines "$GIT_CANDIDATES") Git repositories discovered"
}

dump_git_repositories() {
    info "Dumping repositories"
    : > "$GIT_REPOS"
    while read -r repo; do
        name=$(echo "$repo" | sed 's#https\?://##;s#[/:]#_#g')
        python3 "$GIT_DUMPER" "$repo/.git/" "$REPOS_DIR/$name" >/dev/null 2>&1 &&
        echo "$REPOS_DIR/$name" >> "$GIT_REPOS"
    done < "$GIT_CANDIDATES"
    success "$(count_lines "$GIT_REPOS") repositories dumped"
}

#run_gitjacker() {
#    while read -r repo; do
#        gitjacker "$repo/.git/" >/dev/null 2>&1 || true
#    done < "$GIT_CANDIDATES"
#}

scan_git_secrets() {
    info "Scanning repositories for secrets"
    : > "$GIT_SECRETS"
    while read -r repo; do
        trufflehog filesystem "$repo" --only-verified >> "$GIT_SECRETS" 2>/dev/null || true
    done < "$GIT_REPOS"
    success "Secret scan complete"
}

repository_analysis() {
    find_git_repositories
    dump_git_repositories
    scan_git_secrets
}


#############################################################
# Basic Enrichment Tech Stack / WAF Detection / Screenshots #
#############################################################
fingerprint_technologies() {
    info "Fingerprinting technologies"
    : > "$TECH_JSON"
    while read -r host
    do
        whatweb --log-json=- "$host" 2>/dev/null
    done < "$LIVE_HOSTS" >> "$TECH_JSON"
    success "Technology fingerprinting complete"
}

detect_wafs() {
    info "Detecting WAFs"
    : > "$WAF_JSON"
    while read -r host; do
        wafw00f "$host" -f json 2>/dev/null
    done < "$LIVE_HOSTS" >> "$WAF_JSON"
    success "WAF detection complete"
}

capture_screenshots() {
    info "Capturing screenshots"
    gowitness scan file -f "$LIVE_HOSTS" --write-db
    success "Screenshots captured"
}

find_interesting_hosts() {
    grep -Ei 'admin|grafana|jenkins|kibana|vpn|portal|staging|dashboard|internal' "$LIVE_HOSTS" | sort -u > "${ENRICHMENT_DIR}/interesting_hosts.txt"
    success "$(count_lines "${ENRICHMENT_DIR}/interesting_hosts.txt") interesting hosts identified"
}

asset_enrichment() {
    fingerprint_technologies
    detect_wafs
    capture_screenshots
    find_interesting_hosts
}



######################
# Targeted Detection #
######################
categorize_technologies() {
    jq -r 'select(.plugins.WordPress) | .target' "$TECH_JSON" | sort -u > "$WORDPRESS_HOSTS"
    jq -r 'select(.plugins.Joomla) | .target' "$TECH_JSON" | sort -u > "$JOOMLA_HOSTS"
    jq -r 'select(.plugins.GraphQL) | .target' "$TECH_JSON" | sort -u > "$GRAPHQL_HOSTS"
    success "Technology categorization complete"
}

run_nuclei() {
    info "Running Nuclei"
    nuclei -l "$LIVE_HOSTS" -jsonl -rl 25 -c 25 > "$NUCLEI_RESULTS"
    success "Nuclei complete"
}

find_panels() {
    grep -Ei 'admin|dashboard|jenkins|grafana|kibana|gitlab|jira|vpn' "$LIVE_HOSTS" | sort -u > "$EXPOSED_PANELS"
    success "$(count_lines "$EXPOSED_PANELS") panels identified"
}

find_graphql() {
    grep -Ei '/graphql|/graphiql|/playground' "$EXPANDED_URLS" | sort -u > "$GRAPHQL_HOSTS"
    success "$(count_lines "$GRAPHQL_HOSTS") GraphQL endpoints found"
}

targeted_detection() {
    categorize_technologies
    find_panels
    find_graphql
    run_nuclei
}


###########
# Summary #
###########
count_lines() {
    [[ -f "$1" ]] && wc -l < "$1" || echo 0
}

summary() {

    cat <<EOF

=========================================
Bug Bounty Toolkit Summary
=========================================

[ Scope ]

Wildcard Domains : $(count_lines "$WILDCARD_DOMAINS")
Known Hosts      : $(count_lines "$KNOWN_SUBDOMAINS")
Out Of Scope     : $(count_lines "$OUT_OF_SCOPE")

[ Discovery ]

Discovered Hosts : $(count_lines "$RAW_SUBDOMAINS")
In Scope Hosts   : $(count_lines "$FINAL_SUBDOMAINS")
Live Hosts       : $(count_lines "$LIVE_HOSTS")

[ Historical Content ]

GAU URLs         : $(count_lines "$GAU_RESULTS")
Wayback URLs     : $(count_lines "$WAYBACK_RESULTS")
Unique URLs      : $(count_lines "$HISTORICAL_URLS")

[ URL Discovery ]

Katana URLs      : $(count_lines "$KATANA_URLS")
Unique URLs      : $(count_lines "$ALL_URLS")
Parameters       : $(count_lines "$PARAMS")

[ Candidates ]

XSS Candidates   : $(count_lines "$XSS_CANDIDATES")
SQLi Candidates  : $(count_lines "$SQLI_CANDIDATES")
SSRF Candidates  : $(count_lines "$SSRF_CANDIDATES")
Redirects        : $(count_lines "$REDIRECT_CANDIDATES")

[ JavaScript Analysis ]

JS Files          : $(count_lines "$JS_FILES")
JS Endpoints      : $(count_lines "$JS_ENDPOINTS")
Potential Secrets : $(count_lines "$JS_SECRETS")
Expanded URLs     : $(count_lines "$EXPANDED_URLS")

[ Repository Analysis ]

Git Candidates    : $(count_lines "$GIT_CANDIDATES")
Git Repositories  : $(count_lines "$GIT_REPOS")
Git Secrets       : $(count_lines "$GIT_SECRETS")

[ Asset Enrichment ]

Interesting Hosts : $(count_lines "${ENRICHMENT_DIR}/interesting_hosts.txt")

[ Targeted Detection ]

WordPress Hosts : $(count_lines "$WORDPRESS_HOSTS")
Joomla Hosts    : $(count_lines "$JOOMLA_HOSTS")
GraphQL Targets : $(count_lines "$GRAPHQL_HOSTS")
Panels Found    : $(count_lines "$EXPOSED_PANELS")
Nuclei Results  : $(count_lines "$NUCLEI_RESULTS")

[ Output ]

Discovery Data   : $DISCOVERY_DIR
Content Data     : $CONTENT_DIR
Repos Data       : $REPOS_DIR
Enrichment Data  : $ENRICHMENT_DIR
Screenshot Data  : $SCREENSHOT_DIR
Findings Data    : $FINDINGS_DIR

=========================================

EOF
}


########
# Main #
########
main() {
    check_binaries
    check_repositories
    normalize_scope_files
    enumerate_subdomains
    build_scope
    validate_hosts
    collect_historical_urls
    collect_live_urls
    build_url_inventory
    extract_parameters
    generate_candidates
    javascript_analysis
    repository_analysis
    asset_enrichment
    targeted_detection
    summary
}

main "$@"