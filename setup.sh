#!/usr/bin/env bash

set -euo pipefail

#######################
# Informational Files #
#######################
touch \
    notes.txt \
    credentials.txt

#!/usr/bin/env bash
set -euo pipefail

# Directories
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

mkdir -p \
"$BASE_DIR" \
"$SCOPE_DIR" \
"$DISCOVERY_DIR" \
"$SUBDOMAINS_DIR" \
"$URLS_DIR" \
"$CONTENT_DIR" \
"$CANDIDATES_DIR" \
"$JS_DIR" \
"$JS_RECON_DIR" \
"$GIT_DIR" \
"$INVENTORY_DIR" \
"$SCREENSHOT_DIR" \
"$INFRASTRUCTURE_DIR" \
"$DNS_DIR" \
"$PORTS_DIR"

# Files
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

touch \
"$WILDCARD_DOMAINS" \
"$KNOWN_SUBDOMAINS" \
"$OUT_OF_SCOPE" \
"$ENUM_RESULTS" \
"$RAW_SUBDOMAINS" \
"$FINAL_SUBDOMAINS" \
"$LIVE_HOSTS" \
"$HTTPX_JSON" \
"$GAU_URLS" \
"$KATANA_URLS" \
"$ALL_URLS" \
"$PARAMS" \
"$XSS_CANDIDATES" \
"$SQLI_CANDIDATES" \
"$SSRF_CANDIDATES" \
"$REDIRECT_CANDIDATES" \
"$JS_FILES" \
"$JS_SECRETS" \
"$JS_ENDPOINTS" \
"$LINKFINDER_RAW" \
"$SECRETFINDER_RAW" \
"$EXPANDED_URLS" \
"$GIT_CANDIDATES" \
"$GIT_REPOS" \
"$GIT_SECRETS" \
"$INVENTORY_ALIVE" \
"$INVENTORY_TECH" \
"$INVENTORY_WAF" \
"$INVENTORY_WAF_HOSTS" \
"$INVENTORY_INTERESTING" \
"$NUCLEI_RESULTS" \
"$MX_RECORDS" \
"$TXT_RECORDS" \
"$NS_RECORDS" \
"$CAA_RECORDS" \
"$TAKEOVER_RESULTS" \
"$OPEN_PORTS" \
"$OPEN_PORTS_JSON" \
"$NAABU_TARGETS" \
"$NMAP_RESULTS" \
"notes.txt" \
"credentials.txt"

echo "[+] Recon workspace initialized at: $BASE_DIR"

cat <<EOF

=========================================
Bug Bounty Toolkit Initialized
=========================================

Directories Created for Recon!:

Populate:

  scope/wildcard_domains.txt
  scope/known_subdomains.txt
  scope/out_of_scope.txt

Information Files for Convinience:

  notes.txt - Store any type of information about the program
  credentials.txt - Store any type of created user accounts

Then run:

  ./recon.sh

=========================================

EOF
