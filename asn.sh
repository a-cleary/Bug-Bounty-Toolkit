#!/usr/bin/env bash

set -euo pipefail

#################
# Configuration #
#################
ASN_DIR="asn"

HTTPX_JSON="discovery/live_hosts.json"

IPS="${ASN_DIR}/ips.txt"
ASNS="${ASN_DIR}/asns.txt"
NETBLOCKS="${ASN_DIR}/netblocks.txt"
PTR="${ASN_DIR}/ptr.txt"
DISCOVERED_HOSTS="${ASN_DIR}/discovered_hosts.txt"
LIVE_HOSTS="${ASN_DIR}/live_hosts.txt"

mkdir -p "$ASN_DIR"


###########
# Logging #
###########
info()    { echo "[*] $*"; }
success() { echo "[+] $*"; }
error()   { echo "[-] $*" >&2; }

count_lines() {
    [[ -f "$1" ]] && wc -l < "$1" || echo 0
}


##############
# Validation #
##############
check_requirements() {
    local bins=(jq dig whois httpx)
    for bin in "${bins[@]}"
    do
        command -v "$bin" >/dev/null 2>&1 || {
            error "$bin not found"
            exit 1
        }
    done

    [[ -f "$HTTPX_JSON" ]] || {
        error "$HTTPX_JSON not found"
        exit 1
    }
}


###############
# Extract IPs #
###############
extract_ips() {
    info "Extracting IPs"
    jq -r '.ip // empty' "$HTTPX_JSON" | sort -u > "$IPS"
    success "$(count_lines "$IPS") IPs"
}


#################
# ASN Discovery #
#################
collect_asns() {
    info "Collecting ASN information"
    : > "$ASNS"
    while read -r ip
    do
        whois "$ip" 2>/dev/null | grep -Ei 'originas|origin|aut-num|^as[0-9]+' | sed 's/^[[:space:]]*//' || true
    done < "$IPS" | sort -u > "$ASNS"
    success "$(count_lines "$ASNS") ASN entries"
}


######################
# Netblock Discovery #
######################
collect_netblocks() {
    info "Collecting netblocks"
    : > "$NETBLOCKS"
    while read -r ip
    do
        whois "$ip" 2>/dev/null | grep -Ei 'cidr:|route:|route6:|netrange:' | sed 's/^[[:space:]]*//' || true
    done < "$IPS" | sort -u > "$NETBLOCKS"
    success "$(count_lines "$NETBLOCKS") netblock entries"
}


###################
# PTR Enumeration #
###################
collect_ptr() {
    info "Enumerating PTR records"
    : > "$PTR"
    while read -r ip
    do
        dig +short -x "$ip"
    done < "$IPS" | sed 's/\.$//' | grep -v '^$' | sort -u > "$PTR"
    success "$(count_lines "$PTR") PTR records"
}


#####################
# Extract Hostnames #
#####################
extract_hosts() {
    info "Extracting hostnames"
    grep -E '^[A-Za-z0-9._-]+$' "$PTR" | sort -u > "$DISCOVERED_HOSTS"
    success "$(count_lines "$DISCOVERED_HOSTS") discovered hosts"
}


##################
# Validate Hosts #
##################
validate_hosts() {
    info "Validating hosts"
    httpx -silent -l "$DISCOVERED_HOSTS" > "$LIVE_HOSTS"
    success "$(count_lines "$LIVE_HOSTS") live hosts"
}


###############################
# Interesting Host Extraction #
###############################
find_interesting_hosts() {
    info "Finding interesting infrastructure"
    grep -Ei 'vpn|citrix|jira|git|gitlab|jenkins|grafana|kibana|elastic|prometheus|dev|staging|admin|portal|auth|sso' "$DISCOVERED_HOSTS" | sort -u > "${ASN_DIR}/interesting_hosts.txt" || true
    success "$(count_lines "${ASN_DIR}/interesting_hosts.txt") interesting hosts"
}


###########
# Summary #
###########
summary() {
    echo
    echo "========== ASN SUMMARY =========="
    echo
    echo "IPs               : $(count_lines "$IPS")"
    echo "ASN Entries       : $(count_lines "$ASNS")"
    echo "Netblocks         : $(count_lines "$NETBLOCKS")"
    echo "PTR Records       : $(count_lines "$PTR")"
    echo "Discovered Hosts  : $(count_lines "$DISCOVERED_HOSTS")"
    echo "Interesting Hosts : $(count_lines "${ASN_DIR}/interesting_hosts.txt")"
    echo "Live Hosts        : $(count_lines "$LIVE_HOSTS")"
    echo
}


########
# Main #
########
main() {
    check_requirements
    extract_ips
    collect_asns
    collect_netblocks
    collect_ptr
    extract_hosts
    validate_hosts
    find_interesting_hosts
    summary
}

main "$@"