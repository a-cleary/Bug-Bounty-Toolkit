#!/usr/bin/env bash

STATE_FILE="$WORK_DIR/state/modules.json"

initialize_state() {
    mkdir -p "$WORK_DIR/state"
    if [[ ! -f "$STATE_FILE" ]]
    then
        cat > "$STATE_FILE" <<EOF
{
    "modules": {}
}
EOF
    fi
}

module_completed() {
    local MODULE="$1"
    jq -e --arg mod "$MODULE" '.modules[$mod].status == "completed"' "$STATE_FILE" >/dev/null 2>&1
}

mark_module_started() {
    local MODULE="$1"
    local TMP
    TMP=$(mktemp)

    jq --arg mod "$MODULE" --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.modules[$mod] = {status:"running", started:$time}' "$STATE_FILE" > "$TMP"
    mv "$TMP" "$STATE_FILE"
}

mark_module_completed() {
    local MODULE="$1"
    local TMP
    TMP=$(mktemp)

    jq --arg mod "$MODULE" --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.modules[$mod] = {status:"completed", completed:$time}' "$STATE_FILE" > "$TMP"
    mv "$TMP" "$STATE_FILE"
}

mark_module_failed() {
    local MODULE="$1"
    local TMP
    TMP=$(mktemp)

    jq --arg mod "$MODULE" --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.modules[$mod] = {status:"failed", failed:$time}' "$STATE_FILE" > "$TMP"
    mv "$TMP" "$STATE_FILE"
}