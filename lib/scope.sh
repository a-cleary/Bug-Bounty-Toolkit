#!/usr/bin/env bash

load_scope() {
    local SCOPE_DIR="$WORK_DIR/scope"
    local OUTPUT_DIR="$WORK_DIR/output"
    mkdir -p "$OUTPUT_DIR"

    if [[ ! -f "$SCOPE_DIR/wildcard_domains.txt" ]]
    then
        log_error "Missing wildcard_domains.txt"
        exit 1
    fi

    cat "$SCOPE_DIR/wildcard_domains.txt" "$SCOPE_DIR/known_subdomains.txt" | grep -v '^#' | sed '/^$/d' | sort -u > "$OUTPUT_DIR/scope.txt"
    if [[ ! -s "$OUTPUT_DIR/scope.txt" ]]
    then
        log_error "Scope is empty"
        exit 1
    fi

    log_success "Loaded $(wc -l < "$OUTPUT_DIR/scope.txt") scope entries"
}