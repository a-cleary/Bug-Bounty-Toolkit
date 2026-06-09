#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <target>"
    exit 1
fi

START=$(date +%s)

required=(
    amass
    subfinder
    assetfinder
    httpx
    naabu
    nmap
    gowitness
    katana
)

for tool in "${required[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[!] Missing dependency: $tool"
        exit 1
    fi
done

TARGET="$1"
PROJECT_DIR="$PWD/$TARGET"
INPUT_DIR="$PROJECT_DIR/input"
SUBDOMAIN_DIR="$PROJECT_DIR/subdomains"
RECON_DIR="$PROJECT_DIR/recon"
TOOL_DIR="$HOME/Bug-Bounty-Toolkit"

if [[ ! -d "$TOOL_DIR" ]]; then
    echo "[!] Toolkit directory not found:"
    echo "    $TOOL_DIR"
    exit 1
fi

mkdir -p "$INPUT_DIR"
mkdir -p "$SUBDOMAIN_DIR"
mkdir -p "$RECON_DIR/screenshots"
mkdir -p "$RECON_DIR/nmap"
touch "$INPUT_DIR/wildcards.txt"
touch "$INPUT_DIR/known_subdomains.txt"
touch "$INPUT_DIR/excluded_domains.txt"
touch "$PROJECT_DIR/notes.txt"
touch "$PROJECT_DIR/credentials.txt"

if [[ ! -s "$INPUT_DIR/wildcards.txt" ]]; then
    echo
    echo "[+] Created workspace:"
    echo "    $PROJECT_DIR"
    echo
    echo "[!] Populate:"
    echo "    $INPUT_DIR/wildcards.txt"
    echo "    $INPUT_DIR/known_domains.txt"
    echo "    $INPUT_DIR/excluded_domains.txt"
    echo
    exit 0
fi

echo "[*] Target: $TARGET"
echo "[*] Running subdomain enumeration..."
python3 "$TOOL_DIR/subdomain_enumeration/sub_enum.py" \
    --wildcards "$INPUT_DIR/wildcards.txt" \
    --known "$INPUT_DIR/known_subdomains.txt" \
    --exclude "$INPUT_DIR/excluded_domains.txt" \
    --output "$SUBDOMAIN_DIR/subdomains.txt"
echo "[+] Enumeration complete"

echo "[*] Running reconnaissance..."
python3 "$TOOL_DIR/recon_pipeline/recon.py" \
    --input "$SUBDOMAIN_DIR/subdomains.txt" \
    --output "$RECON_DIR"
echo "[+] Recon complete"
END=$(date +%s)

echo
echo "[+] Results:"
echo "    $PROJECT_DIR"
echo
echo "[+] Runtime: $((END - START)) seconds"