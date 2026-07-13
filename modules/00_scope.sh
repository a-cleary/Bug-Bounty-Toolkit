#!/usr/bin/env bash

MODULE_NAME="SCOPE"
MODULE_DESCRIPTION="Initialize and normalize target scope"
MODULE_DEPENDS=()
MODULE_OUTPUTS=(
"scope/domains.txt"
)

module_run() {
    mkdir -p "$WORK_DIR/scope"
    local KNOWN="$WORK_DIR/scope/known_subdomains.txt"
    local WILDCARDS="$WORK_DIR/scope/wildcard_domains.txt"
    local EXCLUSIONS="$WORK_DIR/scope/out_of_scope.txt"
    local OUTPUT="$WORK_DIR/scope/domains.txt"
    log_info "Initializing scope"

    for FILE in "$KNOWN" "$WILDCARDS" "$EXCLUSIONS"
    do
        if [[ ! -f "$FILE" ]]
        then
            log_error "Missing scope file: $FILE"
            return 1
        fi
    done

    grep -v '^#' "$WILDCARDS" | sed '/^$/d' | sed 's/^\*\.//' > "$WORK_DIR/scope/wildcards_normalized.txt"
    cat "$KNOWN" "$WORK_DIR/scope/wildcards_normalized.txt" | grep -v '^#' | sed '/^$/d' | sort -u > "$OUTPUT"

    if [[ -s "$EXCLUSIONS" ]]
    then
        grep -v '^#' "$EXCLUSIONS" | sed '/^$/d' > "$WORK_DIR/scope/exclusions_normalized.txt"
        if [[ -s "$WORK_DIR/scope/exclusions_normalized.txt" ]]
        then
            grep -Fvxf "$WORK_DIR/scope/exclusions_normalized.txt" "$OUTPUT" > "$OUTPUT.tmp"
            mv "$OUTPUT.tmp" "$OUTPUT"
        fi
    fi

    if [[ ! -s "$OUTPUT" ]]
    then
        log_error "No valid scope entries found"
        return 1
    fi

    local COUNT
    COUNT=$(wc -l < "$OUTPUT")
    log_success "Scope initialized (${COUNT} domains)"
}