#!/usr/bin/env bash

MODULE_NAME="PORTS"
MODULE_DESCRIPTION="Port discovery and service enumeration"
MODULE_DEPENDS=("HTTP")
MODULE_OUTPUTS=(
"ports/naabu.txt"
)

module_run() {
    require_artifact "inventory/live_hosts.txt" || return 1
    mkdir -p "$WORK_DIR/ports"
    log_info "Running naabu"

    run_naabu "$WORK_DIR/inventory/live_hosts.txt" "$WORK_DIR/ports/naabu.txt"

    if [[ ! -s "$WORK_DIR/ports/naabu.txt" ]]
    then
        log_warn "No open ports discovered"
        return 0
    fi

    if command -v nmap >/dev/null
    then
        log_info "Running nmap service detection"
        nmap -iL "$WORK_DIR/ports/naabu.txt" -sV -oA "$WORK_DIR/ports/nmap" >/dev/null 2>&1 || true
    fi

    local PORTS
    PORTS=$(wc -l < "$WORK_DIR/ports/naabu.txt")
    log_success "Ports completed (${PORTS} services)"
}