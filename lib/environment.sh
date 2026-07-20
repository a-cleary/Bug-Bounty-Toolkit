#!/usr/bin/env bash

check_environment() {
    echo "[+] Checking environment"

    if [[ "$EUID" -eq 0 ]]
    then
        echo "[!] Running as root"
    fi

    if ! command -v bash >/dev/null
    then
        echo "[!] bash missing"
        exit 1
    fi

    if ! command -v jq >/dev/null
    then
        echo "[!] jq missing"
        exit 1
    fi

    if ! command -v yq >/dev/null
    then
        echo "[!] yq missing"
        exit 1
    fi

    echo "[+] Environment OK"
}

create_framework_structure() {
    echo "[+] Creating framework directories"

    mkdir -p \
    "$WORK_DIR/scope" \
    "$WORK_DIR/templates" \
    "$WORK_DIR/meta"

    touch \
    "$WORK_DIR/scope/known_subdomains.txt" \
    "$WORK_DIR/scope/wildcard_domains.txt" \
    "$WORK_DIR/scope/out_of_scope.txt"

    echo "[+] Framework directories created"
}

create_scope_templates() {
    cat > "$WORK_DIR/scope/known_subdomains.txt" <<EOF
# Known in-scope assets
#
# Example:
# api.example.com
# app.example.com
EOF

    cat > "$WORK_DIR/scope/wildcard_domains.txt" <<EOF
# Wildcard scope
#
# Example:
# *.example.com
EOF

    cat > "$WORK_DIR/scope/out_of_scope.txt" <<EOF
# Excluded assets
#
# Example:
# admin.example.com
EOF

    echo "[+] Scope templates created"
}

print_next_steps() {
    cat <<EOF


====================================
Recon Framework Ready
====================================


Framework:

$FRAMEWORK_DIR


Scope files:

scope/known_subdomains.txt
scope/wildcard_domains.txt
scope/out_of_scope.txt


Next steps:

1. Edit scope files

2. Add targets:

   scope/known_subdomains.txt
   scope/wildcard_domains.txt


3. Run:

   ./recon.sh


EOF
}