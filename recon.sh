#!/usr/bin/env bash

set -eou pipefail

##### CONFIG #####
# Constants 
MAX_PARALLEL_DOMAINS=5
MAX_JS_WORKERS=$(( $(nproc) * 2 ))
TOP_PORTS=1000

TOOLS_DIR="${HOME}/Tools"
LINKFINDER="${TOOLS_DIR}/LinkFinder/linkfinder.py"
SECRETFINDER="${TOOLS_DIR}/SecretFinder/SecretFinder.py"
GIT_DUMPER="${TOOLS_DIR}/git-dumper/git_dumper.py"

PWD="$(pwd)"
BASE_DIR="${PWD}/recon"
SCOPE_DIR="${PWD}/scope"
DISCOVERY_DIR="${BASE_DIR}/discovery"
SUBDOMAINS_DIR="${DISCOVERY_DIR}/subdomain_enumeration"
URLS_DIR="${DISCOVERY_DIR}/url_enumeration"
CONTENT_DIR="${BASE_DIR}/content"
CANDIDATES_DIR="${CONTENT_DIR}/candidates"
JS_DIR="${CONTENT_DIR}/javascript"
JS_RECON_DIR="${JS_DIR}/recon"
GIT_DIR="${CONTENT_DIR}/git"
INVENTORY_DIR="${BASE_DIR}/inventory"
SCREENSHOT_DIR="${INVENTORY_DIR}/screenshots"
INFRASTRUCTURE_DIR="${BASE_DIR}/infrastructure"
DNS_DIR="${INFRASTRUCTURE_DIR}/dns"     
PORTS_DIR="${INFRASTRUCTURE_DIR}/ports"

WILDCARD_DOMAINS="${SCOPE_DIR}/wildcard_domains.txt"
KNOWN_SUBDOMAINS="${SCOPE_DIR}/known_subdomains.txt"
OUT_OF_SCOPE="${SCOPE_DIR}/out_of_scope.txt"
ENUM_RESULTS="${SUBDOMAINS_DIR}/subdomains.txt"
RAW_SUBDOMAINS="${SUBDOMAINS_DIR}/subdomains_raw.txt"
FINAL_SUBDOMAINS="${SUBDOMAINS_DIR}/all_subdomains.txt"
LIVE_HOSTS="${BASE_DIR}/live_hosts.txt"
HTTPX_JSON="${DISCOVERY_DIR}/live_hosts.json"
GAU_URLS="${URLS_DIR}/historical_urls.txt"
KATANA_URLS="${URLS_DIR}/katana_urls.txt"
ALL_URLS="${BASE_DIR}/all_urls.txt"
PARAMS="${CONTENT_DIR}/params.txt"
XSS_CANDIDATES="${CANDIDATES_DIR}/xss_candidates.txt"
SQLI_CANDIDATES="${CANDIDATES_DIR}/sqli_candidates.txt"
SSRF_CANDIDATES="${CANDIDATES_DIR}/ssrf_candidates.txt"
REDIRECT_CANDIDATES="${CANDIDATES_DIR}/redirect_candidates.txt"
JS_FILES="${JS_DIR}/js_files.txt"
JS_SECRETS="${JS_DIR}/js_secrets.txt"
JS_ENDPOINTS="${JS_DIR}/js_endpoints.txt"
LINKFINDER_RAW="${JS_RECON_DIR}/linkfinder.txt"
SECRETFINDER_RAW="${JS_RECON_DIR}/secretfinder.txt"
EXPANDED_URLS="${BASE_DIR}/expanded_js.txt"
GIT_CANDIDATES="${GIT_DIR}/candidates.txt"
GIT_REPOS="${GIT_DIR}/repos.txt"
GIT_SECRETS="${GIT_DIR}/secrets.txt"
INVENTORY_ALIVE="${INVENTORY_DIR}/alive.tsv"
INVENTORY_TECH="${INVENTORY_DIR}/tech_stack.txt"
INVENTORY_WAF="${INVENTORY_DIR}/wafs.txt"
INVENTORY_WAF_HOSTS="${INVENTORY_DIR}/waf_protected_hosts.txt"
INVENTORY_INTERESTING="${INVENTORY_DIR}/interesting_hosts.txt"
NUCLEI_RESULTS="${BASE_DIR}/nuclei.jsonl"
MX_RECORDS="${DNS_DIR}/mx.txt"
TXT_RECORDS="${DNS_DIR}/txt.txt"
NS_RECORDS="${DNS_DIR}/ns.txt"
CAA_RECORDS="${DNS_DIR}/caa.txt"
TAKEOVER_RESULTS="${INFRASTRUCTURE_DIR}/takeovers.txt"
OPEN_PORTS="${PORTS_DIR}/open_ports.txt"
OPEN_PORTS_JSON="${PORTS_DIR}/open_ports.json"
NAABU_TARGETS="${PORTS_DIR}/naabu_targets.txt"
NMAP_RESULTS="${PORTS_DIR}/nmap.txt"


# Logging to STDOUT
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

timestamp() { date '+%H:%M:%S';  }
info() { printf '%b[%s INFO]%b %s\n' "$BLUE" "$(timestamp)" "$NC" "$1"; }
success() { printf '%b[%s   OK]%b %s\n' "$GREEN" "$(timestamp)" "$NC" "$1"; }
warn() { printf '%b[%s WARN]%b %s\n' "$YELLOW" "$(timestamp)" "$NC" "$1"; }
error() { printf '%b[%s FAIL]%b %s\n' "$RED" "$(timestamp)" "$NC" "$1"; }
count_lines() { [[ -f "$1" ]] && wc -l < "$1" || echo 0; }


##### PASSIVE RECON #####
# Subdomain discovery
normalize_scope_files() {
    info "Normalizing scope files"
    for file in "$WILDCARD_DOMAINS" "$KNOWN_SUBDOMAINS" "$OUT_OF_SCOPE"
    do
        [[ -f "$file" ]] || touch "$file"
        sed '/^#/d;/^[[:space:]]*$/d' "$file" | tr '[:upper:]' '[:lower:]' | sort -u > "${file}.tmp"
        mv "${file}.tmp" "$file"
    done
    success "Scope files normalized"
}

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

# Scope filtering
is_out_of_scope() {
    local host="$1"
    [[ -s "$OUT_OF_SCOPE" ]] || return 1
    while read -r pattern
    do
        [[ -z "$pattern" ]] && continue
        if [[ "$pattern" == *'*'* ]]
        then
            local regex
            regex="$(printf '%s\n' "$pattern" | sed 's/\./\\./g;s/\*/.*/g')"
            [[ "$host" =~ ^${regex}$ ]] && return 0
        else
            [[ "$host" == "$pattern" ]] && return 0
        fi
    done < "$OUT_OF_SCOPE"

    return 1
}

build_scope() {
    info "Filtering subdomains based on scope"
    cat "$ENUM_RESULTS" "$KNOWN_SUBDOMAINS" 2>/dev/null | sed '/^[[:space:]]*$/d' | sort -u > "$RAW_SUBDOMAINS"

    if [[ ! -s "$OUT_OF_SCOPE" ]]
    then
        cp "$RAW_SUBDOMAINS" "$FINAL_SUBDOMAINS"
        success "$(count_lines "$FINAL_SUBDOMAINS") hosts in scope"
        return 0
    fi
    : > "$FINAL_SUBDOMAINS"

    while read -r host
    do
        [[ -z "$host" ]] && continue
        if ! is_out_of_scope "$host"
        then
            echo "$host" >> "$FINAL_SUBDOMAINS"
        fi
    done < "$RAW_SUBDOMAINS"

    success "$(count_lines "$FINAL_SUBDOMAINS") hosts in scope"
}

##### CONTENT DISCOVERY #####
# Live host validation
validate_hosts() {
    info "Validating found subdomains"
    httpx -l "$FINAL_SUBDOMAINS" -json -silent -title -tech-detect -status-code -follow-redirects > "$HTTPX_JSON"
    jq -r '.url' "$HTTPX_JSON" > "$LIVE_HOSTS"
    if [[ ! -s "$LIVE_HOSTS" ]]
    then 
        warn "No live hosts discovered"
        return
    fi 
    success "$(wc -l < "$LIVE_HOSTS") live hosts found"
}

# Content discovery
collect_historical() {
    info "Collecting historical URLs"
    gau --threads 20 < "$LIVE_HOSTS" | sed '/^\s*$/d' | sort -u > "$GAU_URLS"
    success "$(wc -l < "$GAU_URLS") historical URLs collected"
}

collect_live() {
    info "Running katana"
    katana -list "$LIVE_HOSTS" -silent -jc -crawl-duration 10m -timeout 10 > "$KATANA_URLS"
    success "$(wc -l < "$KATANA_URLS") URLs discovered via crawling"
}

build_url_inventory() {
    info "Building URL inventory"
    cat "$GAU_URLS" "$KATANA_URLS" | sed '/^\s*$/d' | sort -u > "$ALL_URLS"
    url_count=$(wc -l < "$ALL_URLS")
    success "${url_count} unique URLs"
    if (( url_count > 1000 ))
    then 
        warn "Large crawl result (${url_count} URLs), later phases may take significant time"
    fi 
}

extract_parameters() {
    info "Extracting parameter names"
    unfurl keys < "$ALL_URLS" | sort -u > "$PARAMS"
    success "$(wc -l < "$PARAMS") unique parameters"
}

generate_candidates() {
    info "Generating candidate URLs"
    gf xss < "$ALL_URLS" > "$XSS_CANDIDATES" || warn "gf pattern 'xss' not found"
    gf sqli < "$ALL_URLS" > "$SQLI_CANDIDATES" || warn "gf pattern 'sqli' not found"
    gf ssrf < "$ALL_URLS" > "$SSRF_CANDIDATES" || warn "gf pattern 'ssrf' not found"
    gf redirect < "$ALL_URLS" > "$REDIRECT_CANDIDATES" || warn "gf pattern 'redirect' not found"
    success "Candidate generation complete"
}

extract_javascript() {
    info "Extracting JavaScript URLs"
    grep -Ei '\.js([?#].*)?$' "$ALL_URLS" | sort -u > "$JS_FILES"
    success "$(count_lines "$JS_FILES") JavaScript files found"
}

content_discovery() {
    collect_historical
    collect_live
    build_url_inventory
    extract_parameters
    generate_candidates
    extract_javascript
}

##### JAVASCRIPT ANALYSIS #####
run_linkfinder() {
    info "Running LinkFinder"
    : > "$LINKFINDER_RAW"
    xargs -a "$JS_FILES" \
        -P "${MAX_JS_WORKERS:-5}" \
        -I{} \
        python3 "$LINKFINDER" -i "{}" -o cli \
        >> "$LINKFINDER_RAW" \
        2>/dev/null || warn "Some LinkFinder executions failed"
        
    sort -u "$LINKFINDER_RAW" > "$JS_ENDPOINTS"
    success "$(count_lines "$JS_ENDPOINTS") endpoints discovered"
}

run_secretfinder() {
    info "Running SecretFinder"
    : > "$SECRETFINDER_RAW"
    [[ -s "$JS_FILES" ]] || {
        warn "No JavaScript files available"
        return 0
    }

    tr '\n' '\0' < "$JS_FILES" |
    xargs -0 \
        -P "${MAX_JS_WORKERS:-5}" \
        -I{} \
        python3 "$SECRETFINDER" -i "{}" -o cli \
        >> "$SECRETFINDER_RAW" \
        2>/dev/null || warn "Some SecretFinder executions failed"

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

##### GitHub Analysis #####
find_git_repositories() {
    info "Checking for exposed git repositories"
    httpx -silent -json -mc 200 -mr "ref: refs/heads/" < <(sed 's#/$##;s#$#/.git/HEAD#' "$LIVE_HOSTS") | jq -r '.url // empty' | sed 's#/.git/HEAD$##' | sort -u > "$GIT_CANDIDATES"
    success "$(count_lines "$GIT_CANDIDATES") Git repositories discovered"
}

dump_git_repositories() {
    info "Dumping repositories"
    : > "$GIT_REPOS"
    [[ -s "$GIT_CANDIDATES" ]] || {
        warn "No Git repositories discovered"
        return 0
    }

    while read -r repo
    do
        name="$(echo "$repo" | sed 's#https\?://##;s#[/:]#_#g')"
        if python3 "$GIT_DUMPER" "${repo}/.git/" "${REPOS_DIR}/${name}" >/dev/null 2>&1
        then
            echo "${REPOS_DIR}/${name}" >> "$GIT_REPOS"
        fi
    done < "$GIT_CANDIDATES"

    success "$(count_lines "$GIT_REPOS") repositories dumped"
}

scan_git_secrets() {
    info "Scanning repositories for secrets"
    : > "$GIT_SECRETS"
    [[ -s "$GIT_REPOS" ]] || {
        warn "No repositories available for scanning"
        return 0
    }

    while read -r repo
    do
        trufflehog filesystem "$repo" --only-verified >> "$GIT_SECRETS" 2>/dev/null || true
    done < "$GIT_REPOS"
    success "Secret scan complete"
}

repository_analysis() {
    find_git_repositories
    dump_git_repositories
    scan_git_secrets
}

##### INVENTORY #####
extract_from_httpx() {
    info "Building inventory from httpx results"
    jq -r '[.url, (.status_code // ""), (.title // ""), ((.tech // []) | join(","))] | @tsv' "$HTTPX_JSON" > "$INVENTORY_ALIVE"
    jq -r '(.tech // [])[]' "$HTTPX_JSON" | sort | uniq -c | sort -rn > "$INVENTORY_TECH"
    jq -r '(.tech // [])[] | select(test("Cloudflare|Akamai|Imperva|Sucuri|F5|AWS WAF|Fastly|DataDome|Incapsula"; "i"))' "$HTTPX_JSON" | sort | uniq -c | sort -rn > "$INVENTORY_WAF"
    jq -r 'select((.tech // []) | join(" ") | test("Cloudflare|Akamai|Imperva|Sucuri|F5|AWS WAF|Fastly|DataDome|Incapsula"; "i"))| .url' "$HTTPX_JSON" | sort -u > "$INVENTORY_WAF_HOSTS"
    jq -r 'select(.status_code == 401 or .status_code == 403 or .status_code == 500 or ((.title // "") | ascii_downcase | test("admin|dashboard|login|signin|portal"))) | .url' "$HTTPX_JSON" | sort -u > "$INVENTORY_INTERESTING"
    success "Inventory created"
}

capture_screenshots() {
    info "Capturing screenshots"
    gowitness scan file -f "$LIVE_HOSTS" --screenshot-path "$SCREENSHOT_DIR" --write-db >/dev/null 2>&1 || true 
    success "Screenshots captured"
}

build_inventory() {
    extract_from_httpx
    capture_screenshots
}

##### INFRASTRUCTURE #####
dns_records() {
    info "Extracting DNS records"
    : > "$MX_RECORDS"
    : > "$TXT_RECORDS"
    : > "$NS_RECORDS"
    : > "$CAA_RECORDS"
    while read -r domain
    do 
        dig +short MX "$domain" >> "$MX_RECORDS"
        dig +short TXT "$domain" >> "$TXT_RECORDS"
        dig +short NS "$domain" >> "$NS_RECORDS"
        dig +short CAA "$domain" >> "$CAA_RECORDS"
    done < "$WILDCARD_DOMAINS"
    sort -u "$MX_RECORDS" -o "$MX_RECORDS"
    sort -u "$TXT_RECORDS" -o "$TXT_RECORDS"
    sort -u "$NS_RECORDS" -o "$NS_RECORDS"
    sort -u "$CAA_RECORDS" -o "$CAA_RECORDS"
}

find_takeovers() {
    info "Checking for subdomain takeovers"
    : > "$TAKEOVER_RESULTS"
    subjack -w "$FINAL_SUBDOMAINS" -t 100 -timeout 30 -ssl -o "$TAKEOVER_RESULTS" 2>/dev/null || true
    grep -vi "not vulnerable" "$TAKEOVER_RESULTS" > "${TAKEOVER_RESULTS}.tmp" 2>/dev/null || true
    mv "${TAKEOVER_RESULTS}.tmp" "$TAKEOVER_RESULTS" 2>/dev/null || true
    success "$(count_lines "$TAKEOVER_RESULTS") potential takeovers identified"
}

normalize_hosts() {
    awk '
    {
        gsub(/^https?:\/\//, "", $0)
        gsub(/\/.*$/, "", $0)
        print $0
    }' "$LIVE_HOSTS" | sort -u > "$NAABU_TARGETS"
}

run_naabu() {
    info "Running naabu"
    naabu -list "$NAABU_TARGETS" -top-ports "$TOP_PORTS" -json -silent > "$OPEN_PORTS_JSON" || true
    jq -r '.host + ":" + (.port|tostring)' "$OPEN_PORTS_JSON" 2>/dev/null | sort -u > "$OPEN_PORTS"
    success "$(count_lines "$OPEN_PORTS") open ports discovered"
}

run_nmap() {
    info "Running nmap service detection"
    [[ -s "$OPEN_PORTS" ]] || {
        warn "No open ports discovered"
        return
    }
    awk -F: '{print $1}' "$OPEN_PORTS" | sort -u | nmap -sV -sC -Pn -iL - -oN "$NMAP_RESULTS" >/dev/null 2>&1 || true
    success "Nmap service detection completed"
}

infrastructure_recon() {
    dns_records
    find_takeovers
    normalize_hosts
    run_naabu
    run_nmap
}

##### VULNERABILITY SCANNING #####
run_nuclei() {
    info "Running Nuclei"
    nuclei -silent -jsonl -rl 25 -c 25 -l "$LIVE_HOSTS" -o "$NUCLEI_RESULTS" || warn "Nuclei encountered errors"
    success "$(count_lines "$NUCLEI_RESULTS") findings identified"
}

main() {
    normalize_scope_files
    enumerate_subdomains
    build_scope
    validate_hosts
    content_discovery
    javascript_analysis
    repository_analysis
    build_inventory
    infrastructure_recon
    run_nuclei
}

main "$@"