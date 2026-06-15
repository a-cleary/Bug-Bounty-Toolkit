#!/usr/bin/env bash

set -euo pipefail

#############
# Variables #
#############
SECRETS_DIR="secrets"

AWS="${SECRETS_DIR}/aws.txt"
GITHUB="${SECRETS_DIR}/github.txt"
SLACK="${SECRETS_DIR}/slack.txt"
JWT="${SECRETS_DIR}/jwt.txt"

STRIPE="${SECRETS_DIR}/stripe.txt"
TWILIO="${SECRETS_DIR}/twilio.txt"
SENDGRID="${SECRETS_DIR}/sendgrid.txt"

GENERIC="${SECRETS_DIR}/generic.txt"
CLOUD_URLS="${SECRETS_DIR}/urls.txt"

SUMMARY="${SECRETS_DIR}/summary.txt"

SEARCH_DIRS=(
    content
    repos
)

declare -A SECRET_PATTERNS=(
    ["aws"]='AKIA[0-9A-Z]{16}'
    ["github"]='gh[pousr]_[A-Za-z0-9]+'
    ["slack"]='xox[baprs]-[A-Za-z0-9-]+'
    ["jwt"]='eyJ[A-Za-z0-9._-]+'
    ["stripe"]='sk_live_[A-Za-z0-9]+'
    ["twilio"]='SK[0-9a-fA-F]{32}'
    ["sendgrid"]='SG\.[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+'
)

declare -A SECRET_FILES=(
    ["aws"]="$AWS"
    ["github"]="$GITHUB"
    ["slack"]="$SLACK"
    ["jwt"]="$JWT"
    ["stripe"]="$STRIPE"
    ["twilio"]="$TWILIO"
    ["sendgrid"]="$SENDGRID"
)


###########
# Logging #
###########
info()    { echo "[*] $*"; }
success() { echo "[+] $*"; }
error()   { echo "[-] $*" >&2; }

count_lines() {
    [[ -f "$1" ]] && wc -l < "$1" || echo 0
}


############
# Helpers #
############
search() {
    grep -RhoE "$1" "${SEARCH_DIRS[@]}" 2>/dev/null || true
}


######################
# Secret Enumeration #
######################
find_secrets() {
    for secret_type in "${!SECRET_PATTERNS[@]}"
    do
        search "${SECRET_PATTERNS[$secret_type]}" |
        sort -u > "${SECRET_FILES[$secret_type]}"
    done
}


#########################
# Generic Secret Search #
#########################
find_generic() {
    grep -RniE 'password|passwd|secret|apikey|api_key|token|bearer|client_secret|private_key|access_key' "${SEARCH_DIRS[@]}" 2>/dev/null > "$GENERIC" || true
}


###################
# Cloud Endpoints #
###################
find_cloud_urls() {
    grep -RhoE 'https?://[^"'"'"' <>]+' "${SEARCH_DIRS[@]}" 2>/dev/null | grep -Ei 'amazonaws\.com|cloudfront\.net|blob\.core\.windows\.net|storage\.googleapis\.com|azurewebsites\.net|appspot\.com' | sort -u > "$CLOUD_URLS" || true
}


#################
# Build Summary #
#################
build_summary() {
    cat > "$SUMMARY" <<EOF
========== SECRETS SUMMARY ==========

AWS Keys      : $(count_lines "$AWS")
GitHub Tokens : $(count_lines "$GITHUB")
Slack Tokens  : $(count_lines "$SLACK")
JWT Tokens    : $(count_lines "$JWT")

Stripe Keys   : $(count_lines "$STRIPE")
Twilio Keys   : $(count_lines "$TWILIO")
SendGrid Keys : $(count_lines "$SENDGRID")

Keyword Hits  : $(count_lines "$GENERIC")
Cloud URLs    : $(count_lines "$CLOUD_URLS")

EOF

}


###########
# Summary #
###########
summary() {
    echo
    cat "$SUMMARY"
    echo
}


########
# Main #
########
main() {
    find_secrets
    find_generic
    find_cloud_urls
    build_summary
    summary
}

main "$@"