#!/usr/bin/env bash

MODULE_NAME="DNS"
MODULE_DESCRIPTION="DNS intelligence collection"
MODULE_DEPENDS=("PERMUTATIONS")
MODULE_OUTPUTS=(
"dns/records.jsonl"
"dns/cloud_candidates.txt"
)

module_run() {
    require_artifact "discovery/subdomains_expanded.txt" || return 1
    mkdir -p "$WORK_DIR/dns"
    local RAW="$WORK_DIR/dns/raw.jsonl"
    log_info "Collecting DNS records"

    run_dnsx "$WORK_DIR/discovery/subdomains_expanded.txt" "$RAW" || return 1
    if [[ ! -s "$RAW" ]]
    then
        log_warn "No DNS records collected"
        return 1
    fi

    local CLEAN="$WORK_DIR/dns/raw_clean.jsonl"
    while IFS= read -r line
    do
        if echo "$line" | jq empty >/dev/null 2>&1
        then
            echo "$line"
        fi
    done < "$RAW" > "$CLEAN"
    mv "$CLEAN" "$RAW"

    local INVALID
    INVALID=$(grep -vc '^{' "$RAW" || true)
    if [[ "$INVALID" -gt 0 ]]
    then
        log_warn "Removed ${INVALID} invalid DNS records"
    fi

    if ! jq -c 'select(type=="object") | {host:.host, a:.a, aaaa:.aaaa, cname:.cname, mx:.mx, ns:.ns, txt:.txt}' "$RAW" > "$WORK_DIR/dns/records.jsonl"
    then
        log_error "Failed parsing dnsx JSON output"
        return 1
    fi 

    if [[ ! -s "$WORK_DIR/dns/records.jsonl" ]]
    then
        log_error "DNS parsing produced no records"
        return 1
    fi

    jq -r 'select((.cname[]? // "") | test("amazonaws|cloudfront|azure|googleapis|fastly|akamai"; "i")) | .host' "$WORK_DIR/dns/records.jsonl" | sort -u > "$WORK_DIR/dns/cloud_candidates.txt"

    local RECORDS
    local CLOUD
    RECORDS=$(wc -l < "$WORK_DIR/dns/records.jsonl")
    CLOUD=$(wc -l < "$WORK_DIR/dns/cloud_candidates.txt")
    log_success "DNS completed (${RECORDS} records, ${CLOUD} cloud candidates)"
}