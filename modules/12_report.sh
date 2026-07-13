#!/usr/bin/env bash

MODULE_NAME="REPORT"
MODULE_DESCRIPTION="Generate reconnaissance report"
MODULE_DEPENDS=("NUCLEI")
MODULE_OUTPUTS=(
"report/summary.json"
"report/findings.md"
)

module_run() {
    mkdir -p "$WORK_DIR/report"
    log_info "Generating report"

    local SUBDOMAINS=0
    local HOSTS=0
    local URLS=0
    local JS_FILES=0
    local API_ENDPOINTS=0
    local NUCLEI_FINDINGS=0
    local GIT_REPOS=0
    local CLOUD_ASSETS=0

    [[ -f "$WORK_DIR/discovery/subdomains.txt" ]] && SUBDOMAINS=$(wc -l < "$WORK_DIR/discovery/subdomains.txt")
    [[ -f "$WORK_DIR/inventory/live_hosts.txt" ]] && HOSTS=$(wc -l < "$WORK_DIR/inventory/live_hosts.txt")
    [[ -f "$WORK_DIR/urls/all.txt" ]] && URLS=$(wc -l < "$WORK_DIR/urls/all.txt")
    [[ -f "$WORK_DIR/javascript/files.txt" ]] && JS_FILES=$(wc -l < "$WORK_DIR/javascript/files.txt")
    [[ -f "$WORK_DIR/api/endpoints.txt" ]] && API_ENDPOINTS=$(wc -l < "$WORK_DIR/api/endpoints.txt")
    [[ -f "$WORK_DIR/vulnerabilities/nuclei.jsonl" ]] && NUCLEI_FINDINGS=$(wc -l < "$WORK_DIR/vulnerabilities/nuclei.jsonl")
    [[ -f "$WORK_DIR/git/repos.txt" ]] && GIT_REPOS=$(wc -l < "$WORK_DIR/git/repos.txt")
    [[ -f "$WORK_DIR/cloud/candidates.txt" ]] && CLOUD_ASSETS=$(wc -l < "$WORK_DIR/cloud/candidates.txt")

    jq -n --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --argjson subdomains "$SUBDOMAINS" --argjson hosts "$HOSTS" --argjson urls "$URLS" --argjson js "$JS_FILES" --argjson api "$API_ENDPOINTS" --argjson nuclei "$NUCLEI_FINDINGS" --argjson git "$GIT_REPOS" --argjson cloud "$CLOUD_ASSETS" '{generated:$generated, assets:{subdomains:$subdomains, hosts:$hosts, urls:$urls, javascript:$js, api_endpoints:$api, cloud_candidates:$cloud, git_repositories:$git}, findings:{nuclei:$nuclei}}' > "$WORK_DIR/report/summary.json"

    cat > "$WORK_DIR/report/findings.md" <<EOF
# Reconnaissance Report

Generated:

$(date -u +"%Y-%m-%dT%H:%M:%SZ")


## Asset Summary

| Category | Count |
|---|---:|
| Subdomains | $SUBDOMAINS |
| Live Hosts | $HOSTS |
| URLs | $URLS |
| JavaScript Files | $JS_FILES |
| API Endpoints | $API_ENDPOINTS |
| Cloud Candidates | $CLOUD_ASSETS |
| Git Repositories | $GIT_REPOS |


## Findings

Nuclei Findings:

$NUCLEI_FINDINGS

EOF

    log_success "Report completed"
}