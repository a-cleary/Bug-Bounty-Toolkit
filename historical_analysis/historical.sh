#!/usr/bin/env bash

set -euo pipefail

# Check for correct usage
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <live_hosts.json> <output_dir>"
    exit 1
fi

# Get subdomain list and output directory
INPUT="$1"
OUTPUT="$2"

# Create file structure and files
mkdir -p "$OUTPUT"
WAYBACK="$OUTPUT/waybackurls.txt"
GAU="$OUTPUT/gau.txt"
URLS="$OUTPUT/historical_urls.txt"
LIVE="$OUTPUT/live_urls.txt"
PARAMS="$OUTPUT/parameters.txt"
DOMAINS="$OUTPUT/domains.txt"
PATHS="$OUTPUT/paths.txt"
SUMMARY="$OUTPUT/analysis.json"

# Fetching from sources
echo "[*] Running waybackurls..."
cat "$INPUT" | jq '.[].host' | tr -d '"' | waybackurls | sort -u > "$WAYBACK"
echo "[*] Running gau..."
cat "$INPUT" | jq '.[].host' | tr -d '"' | gau --threads 20 | sort -u > "$GAU"

# Combine into a single list
echo "[*] Merging results..."
cat "$WAYBACK" "$GAU" | sort -u > "$URLS"

# Probe for what's still living
echo "[*] Probing URLs..."
httpx -silent -mc 200,301,302,307,308,401,403 -l "$URLS" > "$LIVE"

# Extracting different elements
echo "[*] Extracting parameters..."
cat "$LIVE" | unfurl keys | sort -u > "$PARAMS"
echo "[*] Extracting domains..."
cat "$LIVE" | unfurl domains | sort -u > "$DOMAINS"
echo "[*] Extracting paths..."
cat "$LIVE" | unfurl paths | sort -u > "$PATHS"

# Aggregating into a singular JSON file
echo "[*] Building JSON summary..."
jq -n \
    --argfile urls <(jq -R . < "$LIVE" | jq -s .) \
    --argfile params <(jq -R . < "$PARAMS" | jq -s .) \
    --argfile domains <(jq -R . < "$DOMAINS" | jq -s .) \
    --argfile paths <(jq -R . < "$PATHS" | jq -s .) \
    '{
        generated_at: now | todate,
        live_urls: $urls,
        parameters: $params,
        domains: $domains,
        paths: $paths
    }' \
    > "$SUMMARY"

echo "[+] Complete"