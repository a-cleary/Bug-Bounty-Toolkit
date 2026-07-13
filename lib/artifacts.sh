#!/usr/bin/env bash

ARTIFACT_INDEX="$WORK_DIR/artifacts.json"

artifact_path() {
    local ARTIFACT="$1"
    if [[ "$ARTIFACT" = /* ]]
    then
        echo "$ARTIFACT"
    else
        echo "$WORK_DIR/$ARTIFACT"
    fi
}

artifact_exists() {
    local FILE
    FILE=$(artifact_path "$1")
    [[ -f "$FILE" ]]
}

artifact_empty() {
    local FILE
    FILE=$(artifact_path "$1")
    [[ ! -s "$FILE" ]]
}

require_artifact() {
    local FILE
    FILE=$(artifact_path "$1")
    if [[ ! -f "$FILE" ]]
    then
        log_warn "Missing artifact: ${FILE#$WORK_DIR/}"
        return 1
    fi

    if [[ ! -s "$FILE" ]]
    then
        log_warn "Empty artifact: ${FILE#$WORK_DIR/}"
        return 1
    fi

    return 0
}

create_artifact() {
    local FILE
    FILE=$(artifact_path "$1")
    mkdir -p "$(dirname "$FILE")"
    : > "$FILE"
}

artifact_lines() {
    local FILE
    FILE=$(artifact_path "$1")
    if [[ ! -f "$FILE" ]]
    then
        echo 0
        return
    fi

    wc -l < "$FILE"
}

validate_outputs() {
    local MODULE="$1"
    source "$MODULE"
    for OUTPUT in "${MODULE_OUTPUTS[@]:-}"
    do
        require_artifact "$OUTPUT" || return 1
    done

    return 0
}

generate_artifact_index() {
    mkdir -p "$WORK_DIR"
    cat > "$ARTIFACT_INDEX" <<EOF
{
    "generated":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "artifacts":[
EOF

    find "$WORK_DIR" -type f | sort | jq -R . | paste -sd "," - >> "$ARTIFACT_INDEX"

    cat >> "$ARTIFACT_INDEX" <<EOF

]
}
EOF

}