#!/usr/bin/env bash

set -eou pipefail

#################
# Configuration #
#################
DNS_DIR="infrastructure/dns"

MX="${DNS_DIR}/mx.txt"
TXT="${DNS_DIR}/txt.txt"
NS="${DNS_DIR}/ns.txt"
CAA="${DNS_DIR}/caa.txt"


collect_mx() {
    : > "$MX"
    while read -r domain
    do
        dig +short MX "$domain" >> "$MX"
    done < scope/wildcard_domains.txt
    sort -u "$MX" -o "$MX"
}

collect_txt() {
    : > "$TXT"
    while read -r domain
    do
        dig +short TXT "$domain" >> "$TXT"
    done < scope/wildcard_domains.txt
    sort -u "$TXT" -o "$TXT"
}

collect_ns() {
    : > "$NS"
    while read -r domain
    do
        dig +short NS "$domain" >> "$NS"
    done < scope/wildcard_domains.txt
    sort -u "$NS" -o "$NS"
}

collect_caa() {
    : > "$CAA"
    while read -r domain
    do
        dig +short CAA "$domain" >> "$CAA"
    done < scope/wildcard_domains.txt
    sort -u "$CAA" -o "$CAA"
}

find_identity_hosts() {
    grep -Ei 'auth|oauth|login|sso|id|identity' discovery/live_hosts.txt | sort -u > infrastructure/identity/identity.txt
}

find_developer_hosts() {
    grep -Ei 'git|gitlab|jenkins|ci|cd|build|registry|artifactory|devops' discovery/live_hosts.txt | sort -u > infrastructure/developer/developer_tools.txt
}

find_monitoring_hosts() {
    grep -Ei 'grafana|kibana|elastic|prometheus|jaeger' discovery/live_hosts.txt | sort -u > infrastructure/monitoring/monitoring.txt
}

main() {
    collect_mx
    collect_txt
    collect_ns
    collect_caa
    find_identity_hosts
    find_developer_hosts
    find_monitoring_hosts
}

main "$@"