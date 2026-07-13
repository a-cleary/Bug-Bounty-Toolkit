#!/usr/bin/env bash

MODULE_NAME="CLOUD"
MODULE_DESCRIPTION="Cloud asset discovery"
MODULE_DEPENDS=("DNS")
MODULE_OUTPUTS=(
"cloud/candidates.txt"
"cloud/s3.txt"
"cloud/azure.txt"
"cloud/gcp.txt"
)

module_run() {
    require_artifact "dns/cloud_candidates.txt" || return 1
    mkdir -p "$WORK_DIR/cloud"
    cp "$WORK_DIR/dns/cloud_candidates.txt" "$WORK_DIR/cloud/candidates.txt"
    touch "$WORK_DIR/cloud/s3.txt" "$WORK_DIR/cloud/azure.txt" "$WORK_DIR/cloud/gcp.txt"

    while read -r HOST
    do
        [[ -z "$HOST" ]] && continue
        if echo "$HOST" | grep -Ei 's3|amazonaws|cloudfront'
        then
            echo "$HOST" >> "$WORK_DIR/cloud/s3.txt"
        fi

        if echo "$HOST" | grep -Ei 'azure|blob|windows.net'
        then
            echo "$HOST" >> "$WORK_DIR/cloud/azure.txt"
        fi

        if echo "$HOST" | grep -Ei 'googleapis|storage.googleapis'
        then
            echo "$HOST" >> "$WORK_DIR/cloud/gcp.txt"
        fi
    done < "$WORK_DIR/cloud/candidates.txt"

    sort -u "$WORK_DIR/cloud/s3.txt" -o "$WORK_DIR/cloud/s3.txt"
    sort -u "$WORK_DIR/cloud/azure.txt" -o "$WORK_DIR/cloud/azure.txt"
    sort -u "$WORK_DIR/cloud/gcp.txt" -o "$WORK_DIR/cloud/gcp.txt"

    local TOTAL
    local S3
    local AZURE
    local GCP
    TOTAL=$(wc -l < "$WORK_DIR/cloud/candidates.txt")
    S3=$(wc -l < "$WORK_DIR/cloud/s3.txt")
    AZURE=$(wc -l < "$WORK_DIR/cloud/azure.txt")
    GCP=$(wc -l < "$WORK_DIR/cloud/gcp.txt")
    log_success "Cloud completed (${TOTAL} candidates, ${S3} S3, ${AZURE} Azure, ${GCP} GCP)"
}