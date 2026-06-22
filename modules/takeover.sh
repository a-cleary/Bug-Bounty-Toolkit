#!/usr/bin/env bash

set -euo pipefail

#############
# Variables #
#############
TAKEOVER_DIR="takeover"

SUBDOMAINS="discovery/all_subdomains.txt"

TAKEOVER_RESULTS="${TAKEOVER_DIR}/takeovers.txt"
TAKEOVER_JSON="${TAKEOVER_DIR}/takeovers.json"


##########
# Colors #
##########
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'


###########
# Logging #
###########
timestamp() {
    date '+%H:%M:%S'
}

info() {
    printf '%b[%s INFO]%b %s\n' "$BLUE" "$(timestamp)" "$NC" "$1"
}

success() {
    printf '%b[%s OK]%b %s\n' "$GREEN" "$(timestamp)" "$NC" "$1"
}

warn() {
    printf '%b[%s WARN]%b %s\n' "$YELLOW" "$(timestamp)" "$NC" "$1"
}

error() {
    printf '%b[%s FAIL]%b %s\n' "$RED" "$(timestamp)" "$NC" "$1"
}

count_lines() {
    [[ -f "$1" ]] && wc -l < "$1" || echo 0
}


################
# Requirements #
################
check_requirements() {
    command -v subjack >/dev/null 2>&1 || {
        error "subjack not found"
        exit 1
    }
}


######################
# Subdomain Takeover #
######################
find_takeovers() {
    info "Checking for subdomain takeovers"
    subjack -w "$SUBDOMAINS" -t 100 -timeout 30 -ssl -v -o "$TAKEOVER_RESULTS" 2>/dev/null || true

    success "$(count_lines "$TAKEOVER_RESULTS") potential takeovers identified"
}


###########
# Summary #
###########
summary() {
    echo
    echo "========== TAKEOVER SUMMARY =========="
    echo
    echo "Potential Takeovers : $(count_lines "$TAKEOVER_RESULTS")"
    echo
}


########
# Main #
########
main() {
    check_requirements
    find_takeovers
    summary
}

main "$@"