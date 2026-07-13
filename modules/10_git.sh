#!/usr/bin/env bash

MODULE_NAME="GIT"
MODULE_DESCRIPTION="Git repository discovery and secret analysis"
MODULE_DEPENDS=("URLS")
MODULE_OUTPUTS=(
"git/candidates.txt"
"git/repos.txt"
"git/secrets.txt"
)

module_run() {
    require_artifact "urls/all.txt" || return 1
    mkdir -p "$WORK_DIR/git/repos"
    touch "$WORK_DIR/git/candidates.txt" "$WORK_DIR/git/repos.txt" "$WORK_DIR/git/secrets.txt"

    log_info "Searching for exposed Git repositories"
    grep -Ei '/\.git($|/|\\?)' "$WORK_DIR/urls/all.txt" | sed 's#/.git.*#/.git#' | sort -u > "$WORK_DIR/git/candidates.txt" || true

    if [[ ! -s "$WORK_DIR/git/candidates.txt" ]]
    then
        log_warn "No Git candidates found"
        return 0
    fi

    while read -r URL
    do
        [[ -z "$URL" ]] && continue
        local NAME
        NAME=$(echo "$URL" | md5sum | awk '{print $1}')

        if command -v git-dumper >/dev/null
        then
            git-dumper "$URL" "$WORK_DIR/git/repos/$NAME" >/dev/null 2>&1 || true
        fi
    done < "$WORK_DIR/git/candidates.txt"

    find "$WORK_DIR/git/repos" -type d -name ".git" | sed 's#/.git##' | sort -u > "$WORK_DIR/git/repos.txt"

    if command -v trufflehog >/dev/null
    then
        log_info "Scanning Git repositories for secrets"
        while read -r REPO
        do
            trufflehog filesystem "$REPO" --json >> "$WORK_DIR/git/secrets.txt" 2>/dev/null || true
        done < "$WORK_DIR/git/repos.txt"
    fi

    local CANDIDATES
    local REPOS
    local SECRETS
    CANDIDATES=$(wc -l < "$WORK_DIR/git/candidates.txt")
    REPOS=$(wc -l < "$WORK_DIR/git/repos.txt")
    SECRETS=$(wc -l < "$WORK_DIR/git/secrets.txt")
    log_success "Git completed (${CANDIDATES} candidates, ${REPOS} repos, ${SECRETS} secrets)"
}