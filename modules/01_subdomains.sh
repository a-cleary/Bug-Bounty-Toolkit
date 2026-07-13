#!/usr/bin/env bash

MODULE_NAME="SUBDOMAINS"
MODULE_DESCRIPTION="Enumerate subdomains"
MODULE_DEPENDS=("SCOPE")
MODULE_OUTPUTS=(
"discovery/subdomains.txt"
)

module_run() {
    require_artifact "scope/wildcard_domains.txt" || return 1
    mkdir -p "$WORK_DIR/discovery"
    local TMP_DIR="$WORK_DIR/cache/subdomains"
    mkdir -p "$TMP_DIR"

    while read -r DOMAIN
    do
        [[ -z "$DOMAIN" ]] && continue
        log_info "Enumerating $DOMAIN"
        run_subfinder "$DOMAIN" "$TMP_DIR/subfinder-$DOMAIN.txt"

        if command -v amass >/dev/null
        then
            run_amass "$DOMAIN" "$TMP_DIR/amass-$DOMAIN.txt"
        fi
    done < "$WORK_DIR/scope/domains.txt"

    cat "$TMP_DIR"/*.txt 2>/dev/null | sed '/^$/d' | sort -u > "$WORK_DIR/discovery/subdomains.txt"

    if [[ ! -s "$WORK_DIR/discovery/subdomains.txt" ]]
    then
        log_warn "No subdomains discovered"
        return 1
    fi

    local COUNT
    COUNT=$(wc -l < "$WORK_DIR/discovery/subdomains.txt")
    log_success "Subdomains completed (${COUNT} assets)"
}