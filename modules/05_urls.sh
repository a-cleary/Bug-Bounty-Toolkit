#!/usr/bin/env bash

MODULE_NAME="URLS"
MODULE_DESCRIPTION="URL discovery and collection"
MODULE_DEPENDS=("HTTP")
MODULE_OUTPUTS=(
"urls/all.txt"
)

module_run() {
    require_artifact "inventory/live_hosts.txt" || return 1
    mkdir -p "$WORK_DIR/urls"
    local DOMAINS="$WORK_DIR/urls/domains.txt"

    sed 's#https\?://##' "$WORK_DIR/inventory/live_hosts.txt" | cut -d/ -f1 | sort -u > "$DOMAINS"
    while read -r DOMAIN
    do
        [[ -z "$DOMAIN" ]] && continue
        log_info "Collecting URLs for $DOMAIN"
        run_waybackurls "$DOMAIN" "$WORK_DIR/urls/wayback-$DOMAIN.txt"

        if command -v gau >/dev/null
        then
            run_gau "$DOMAIN" "$WORK_DIR/urls/gau-$DOMAIN.txt"
        fi
    done < "$DOMAINS"

    if command -v katana >/dev/null
    then
        run_katana "$WORK_DIR/inventory/live_hosts.txt" "$WORK_DIR/urls/katana.txt"
    fi

    cat "$WORK_DIR/urls"/*.txt 2>/dev/null | sed '/^$/d' | sort -u > "$WORK_DIR/urls/all.txt"
    if [[ ! -s "$WORK_DIR/urls/all.txt" ]]
    then
        log_warn "No URLs discovered"
        return 1
    fi

    local COUNT
    COUNT=$(wc -l < "$WORK_DIR/urls/all.txt")
    log_success "URLs completed (${COUNT} URLs)"
}