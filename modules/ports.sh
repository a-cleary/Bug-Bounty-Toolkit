#!/usr/bin/env bash

set -euo pipefail

#############
# Variables #
#############
PORTS_DIR="ports"

LIVE_HOSTS="discovery/live_hosts.txt"

OPEN_PORTS="${PORTS_DIR}/open_ports.txt"
OPEN_PORTS_JSON="${PORTS_DIR}/open_ports.json"

NAABU_TARGETS="${PORTS_DIR}/naabu_targets.txt"

NMAP_RESULTS="${PORTS_DIR}/nmap.txt"

TOP_PORTS=1000


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
    local bins=(naabu nmap jq)

    for bin in "${bins[@]}"
    do
        command -v "$bin" >/dev/null 2>&1 || {
            error "$bin not found"
            exit 1
        }
    done
}


###############
# Naabu Scan #
###############
normalize_hosts() {
    awk '
    {
        gsub(/^https?:\/\//, "", $0)
        gsub(/\/.*$/, "", $0)
        print $0
    }' "$LIVE_HOSTS" | sort -u > "$NAABU_TARGETS"
}

run_naabu() {
    info "Running naabu"
    naabu -list "$NAABU_TARGETS" -top-ports "$TOP_PORTS" -json -silent > "$OPEN_PORTS_JSON" || true
    jq -r '.host + ":" + (.port|tostring)' "$OPEN_PORTS_JSON" 2>/dev/null | sort -u > "$OPEN_PORTS"

    success "$(count_lines "$OPEN_PORTS") open ports discovered"
}


##############
# Nmap Scan #
##############
run_nmap() {
    info "Running nmap service detection"
    [[ -s "$OPEN_PORTS" ]] || {
        warn "No open ports discovered"
        return
    }
    awk -F: '{print $1}' "$OPEN_PORTS" | sort -u | nmap -sV -sC -Pn -iL - -oN "$NMAP_RESULTS" >/dev/null 2>&1 || true

    success "Nmap service detection completed"
}


###########
# Summary #
###########
summary() {
    echo
    echo "========== PORT SUMMARY =========="
    echo
    echo "Open Ports : $(count_lines "$OPEN_PORTS")"
    echo
}


########
# Main #
########
main() {
    check_requirements
    normalize_hosts
    run_naabu
    run_nmap
    summary
}

main "$@"