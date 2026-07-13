#!/usr/bin/env bash

MODULE_NAME="JAVASCRIPT"
MODULE_DESCRIPTION="JavaScript discovery and analysis"
MODULE_DEPENDS=("URLS")
MODULE_OUTPUTS=(
"javascript/files.txt"
"javascript/endpoints.txt"
"javascript/secrets.txt"
)

module_run() {
    require_artifact "urls/all.txt" || return 1
    mkdir -p "$WORK_DIR/javascript/raw"
    local JS_LIST="$WORK_DIR/javascript/files.txt"

    grep -Ei '\.js($|\?)' "$WORK_DIR/urls/all.txt" | sort -u > "$JS_LIST"
    if [[ ! -s "$JS_LIST" ]]
    then
        log_warn "No JavaScript files discovered"
        touch "$WORK_DIR/javascript/endpoints.txt" "$WORK_DIR/javascript/secrets.txt"

        return 0
    fi

    log_info "Downloading JavaScript files"
    while read -r URL
    do
        local HASH
        HASH=$(echo "$URL" | md5sum | awk '{print $1}')
        curl -ksL "$URL" -o "$WORK_DIR/javascript/raw/$HASH.js" 2>/dev/null || true
    done < "$JS_LIST"

    touch "$WORK_DIR/javascript/endpoints.txt" "$WORK_DIR/javascript/secrets.txt"
    if command -v linkfinder >/dev/null
    then
        log_info "Extracting JavaScript endpoints"
        while read -r FILE
        do
            python3 "$LinkFinder" -i "$FILE" -o cli >> "$WORK_DIR/javascript/endpoints.txt" 2>/dev/null || true
        done < <(find "$WORK_DIR/javascript/raw" -type f)
    fi

    if command -v SecretFinder >/dev/null
    then
        log_info "Searching JavaScript secrets"
        while read -r FILE
        do
            python3 "$SecretFinder" -i "$FILE" -o cli >> "$WORK_DIR/javascript/secrets.txt" 2>/dev/null || true
        done < <(find "$WORK_DIR/javascript/raw" -type f)
    fi

    sort -u "$WORK_DIR/javascript/endpoints.txt" -o "$WORK_DIR/javascript/endpoints.txt"
    sort -u "$WORK_DIR/javascript/secrets.txt" -o "$WORK_DIR/javascript/secrets.txt"

    local FILES
    local ENDPOINTS
    local SECRETS
    FILES=$(wc -l < "$WORK_DIR/javascript/files.txt")
    ENDPOINTS=$(wc -l < "$WORK_DIR/javascript/endpoints.txt")
    SECRETS=$(wc -l < "$WORK_DIR/javascript/secrets.txt")
    log_success "JS completed (${FILES} files, ${ENDPOINTS} endpoints, ${SECRETS} secrets)"
}