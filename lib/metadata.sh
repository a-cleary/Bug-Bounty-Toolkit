#!/usr/bin/env bash

RUN_FILE="$WORK_DIR/run.json"

initialize_metadata() {
    mkdir -p "$WORK_DIR"
    cat > "$RUN_FILE" <<EOF
{
    "framework": "Bug-Bounty-Automation-Framework",
    "version": "1.0.0",
    "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "completed": null,
    "status": "running",
    "work_dir": "$WORK_DIR",
    "modules": [],
    "artifacts": 0
}
EOF
}

record_module_execution() {
    local MODULE="$1"
    local TMP
    TMP=$(mktemp)

    jq --arg mod "$MODULE" '.modules += [$mod]' "$RUN_FILE" > "$TMP"
    mv "$TMP" "$RUN_FILE"
}

finalize_metadata() {
    local STATUS="${1:-completed}"
    local ARTIFACT_COUNT
    ARTIFACT_COUNT=$(find "$WORK_DIR" -type f | wc -l)
    local TMP
    TMP=$(mktemp)

    jq --arg completed "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg status "$STATUS" --argjson artifacts "$ARTIFACT_COUNT" '.completed=$completed | .status=$status | .artifacts=$artifacts' "$RUN_FILE" > "$TMP"
    mv "$TMP" "$RUN_FILE"
}