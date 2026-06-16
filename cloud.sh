#!/usr/bin/env bash

set -eou pipefail

#################
# Configuration #
#################
CLOUD_DIR="cloud"

CLOUD_ASSETS="${CLOUD_DIR}/cloud_assets.txt"
STORAGE="${CLOUD_DIR}/storage.txt"

AWS="${CLOUD_DIR}/aws/aws.txt"
AZURE="${CLOUD_DIR}/azure/azure.txt"
GCP="${CLOUD_DIR}/gcp/gcp.txt"


extract_cloud_assets() {
    grep -RhiE 'amazonaws\.com|cloudfront\.net|blob\.core\.windows\.net|azurewebsites\.net|storage\.googleapis\.com|appspot\.com' content repos 2>/dev/null | sort -u > "$CLOUD_ASSETS"
}

extract_aws() {
    grep -Ei 'amazonaws\.com|cloudfront\.net|execute-api\.' "$CLOUD_ASSETS" | sort -u > "$AWS"
}

extract_azure() {
    grep -Ei 'blob\.core\.windows\.net|azurewebsites\.net|azurefd\.net' "$CLOUD_ASSETS" | sort -u > "$AZURE"
}

extract_gcp() {
    grep -Ei 'storage\.googleapis\.com|appspot\.com|cloudfunctions\.net' "$CLOUD_ASSETS" | sort -u > "$GCP"
}

extract_storage() {
    grep -Ei 's3|bucket|storage|blob|uploads|files|media|static' "$CLOUD_ASSETS" | sort -u > "$STORAGE"
}

main() {
    extract_cloud_assets
    extract_aws
    extract_azure
    extract_gcp
    extract_storage
}

main "$@"   