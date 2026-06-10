#!/usr/bin/env bash

set -euo pipefail

# Quick check if the script is ran corretly
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
    waybackurls
    gau
    unfurl
    jq
)

# Deps check
for tool in "${required[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[!] Missing dependency: $tool"
        exit 1
    fi
done

# Create folder structure / necessary files
TARGET="$1"
PROJECT_DIR="$PWD/$TARGET"
INPUT_DIR="$PROJECT_DIR/input"
SUBDOMAIN_DIR="$PROJECT_DIR/subdomains"
RECON_DIR="$PROJECT_DIR/recon"
HISTORICAL_DIR="$PROJECT_DIR/historical"
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
mkdir -p "$HISTORICAL_DIR"
touch "$INPUT_DIR/wildcards.txt"
touch "$INPUT_DIR/known_subdomains.txt"
touch "$INPUT_DIR/excluded_domains.txt"

# These aren't _required_ but notes and a place to note test creds may be nice
touch "$PROJECT_DIR/notes.txt"
touch "$PROJECT_DIR/credentials.txt"

# If wildcards is empty, populate them
#   If you have wildcards: re-run
#   Else: Run the recon_pipeline/recon.py script directly as shown below 
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

# Scanning and enumeration starts here
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

echo "[*] Performing historical analysis..."
bash "$TOOL_DIR/historical_analysis/historical.sh" "$RECON_DIR/live_hosts.json" "$HISTORICAL_DIR"
echo "[+] Historical analysis complete"
END=$(date +%s)

echo
echo "[+] Results:"
echo "    $PROJECT_DIR"
echo "    Check ${RECON_DIR}/assets.json for aggregated scan data"
echo
echo "[+] Runtime: $((END - START)) seconds"