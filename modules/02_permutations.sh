#!/usr/bin/env bash

MODULE_NAME="PERMUTATIONS"
MODULE_DESCRIPTION="Generate additional DNS candidates"
MODULE_DEPENDS=("SUBDOMAINS")
MODULE_OUTPUTS=(
"discovery/subdomains_expanded.txt"
)

module_run() {
    require_artifact "discovery/subdomains.txt" || return 1
    mkdir -p "$WORK_DIR/discovery/permutations"
    local GENERATED="$WORK_DIR/discovery/permutations/generated.txt"
    local VALID="$WORK_DIR/discovery/permutations/valid.txt"

    if ! command -v alterx >/dev/null
    then
        log_warn "alterx unavailable"
        cp "$WORK_DIR/discovery/subdomains.txt" "$WORK_DIR/discovery/subdomains_expanded.txt"
        return 0
    fi

    run_alterx "$WORK_DIR/discovery/subdomains.txt" "$GENERATED"

    if [[ ! -s "$GENERATED" ]]
    then
        log_warn "No permutations generated"
        cp "$WORK_DIR/discovery/subdomains.txt" "$WORK_DIR/discovery/subdomains_expanded.txt"
        return 0
    fi

    if command -v dnsx >/dev/null
    then
        run_dnsx "$GENERATED" "$WORK_DIR/discovery/permutations/valid.json"

        jq -r '.host' "$WORK_DIR/discovery/permutations/valid.json" 2>/dev/null | sort -u > "$VALID"
    fi

    cat "$WORK_DIR/discovery/subdomains.txt" "$VALID" 2>/dev/null | sort -u > "$WORK_DIR/discovery/subdomains_expanded.txt"
    local COUNT
    COUNT=$(wc -l < "$WORK_DIR/discovery/subdomains_expanded.txt")

    log_success "Permutations completed (${COUNT} assets)"
}