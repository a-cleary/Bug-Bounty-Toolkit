#!/usr/bin/env bash

MODULE_NAME="HTTP"
MODULE_DESCRIPTION="HTTP fingerprinting and asset inventory"
MODULE_DEPENDS=("DNS")
MODULE_OUTPUTS=(
"inventory/http.jsonl"
"inventory/live_hosts.txt"
)

module_run() {
    require_artifact "discovery/subdomains_expanded.txt" || return 1
    mkdir -p "$WORK_DIR/inventory"
    local RAW="$WORK_DIR/inventory/http.jsonl"
    log_info "Running httpx"

    run_httpx "$WORK_DIR/discovery/subdomains_expanded.txt" "$RAW"
    if [[ ! -s "$RAW" ]]
    then
        log_warn "No HTTP services discovered"
        touch "$WORK_DIR/inventory/live_hosts.txt"
        return 0
    fi

    jq -c '{host:.host, url:.url, status:.status_code, title:.title, server:.webserver, technologies:.tech}' "$RAW" > "$WORK_DIR/inventory/assets.jsonl"
    jq -r '.url' "$WORK_DIR/inventory/assets.jsonl" | sort -u > "$WORK_DIR/inventory/live_hosts.txt"

    if command -v wafw00f >/dev/null
    then
        log_info "Detecting WAF"
        while read -r HOST
        do
            wafw00f "$HOST" >> "$WORK_DIR/inventory/waf.txt" 2>/dev/null || true
        done < "$WORK_DIR/inventory/live_hosts.txt"
    fi

    if command -v gowitness >/dev/null
    then
        log_info "Capturing screenshots"
        gowitness scan file -f "$WORK_DIR/inventory/live_hosts.txt" --silent --destination "$WORK_DIR/inventory/screenshots" >/dev/null 2>&1 || true
    fi

    local COUNT
    COUNT=$(wc -l < "$WORK_DIR/inventory/live_hosts.txt")
    log_success "HTTP completed (${COUNT} live hosts)"
}