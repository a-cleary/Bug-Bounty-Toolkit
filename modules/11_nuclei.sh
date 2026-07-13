#!/usr/bin/env bash

MODULE_NAME="NUCLEI"
MODULE_DESCRIPTION="Vulnerability scanning with nuclei"
MODULE_DEPENDS=("HTTP")
MODULE_OUTPUTS=(
"vulnerabilities/nuclei.jsonl"
)

module_run() {
    require_artifact "inventory/live_hosts.txt" || return 1
    mkdir -p "$WORK_DIR/vulnerabilities"
    local OUTPUT="$WORK_DIR/vulnerabilities/nuclei.jsonl"
    touch "$OUTPUT"

    if ! command -v nuclei >/dev/null
    then
        log_warn "nuclei unavailable"
        return 0
    fi

    log_info "Running nuclei"
    nuclei -silent -jsonl -l "$WORK_DIR/inventory/live_hosts.txt" -o "$OUTPUT" -rate-limit "${CONFIG_NUCLEI_RATE:-25}" -concurrency "${CONFIG_NUCLEI_THREADS:-25}" >/dev/null 2>&1 || true

    if [[ ! -s "$OUTPUT" ]]
    then
        log_warn "No nuclei findings"
        return 0
    fi

    local FINDINGS
    FINDINGS=$(wc -l < "$OUTPUT")
    log_success "Nuclei completed (${FINDINGS} findings)"
}