#!/usr/bin/env bash

MODULE_NAME="API"
MODULE_DESCRIPTION="API endpoint discovery"
MODULE_DEPENDS=("JAVASCRIPT")
MODULE_OUTPUTS=(
"api/endpoints.txt"
"api/graphql.txt"
"api/openapi.txt"
"api/api.json"
)

module_run() {
    require_artifact "urls/all.txt" || return 1
    mkdir -p "$WORK_DIR/api"
    touch "$WORK_DIR/api/endpoints.txt" "$WORK_DIR/api/graphql.txt" "$WORK_DIR/api/openapi.txt"
    
    cat "$WORK_DIR/urls/all.txt" "$WORK_DIR/javascript/endpoints.txt" 2>/dev/null | grep -Ei '/(api|graphql|swagger|openapi|api-docs|v[0-9]+|rest|jsonrpc)' | sort -u > "$WORK_DIR/api/endpoints.txt" || true
    grep -Ei 'graphql' "$WORK_DIR/api/endpoints.txt" > "$WORK_DIR/api/graphql.txt" || true
    grep -Ei 'swagger|openapi|api-docs|docs' "$WORK_DIR/urls/all.txt" > "$WORK_DIR/api/openapi.txt" || true

    jq -n --argfile endpoints <(jq -R . "$WORK_DIR/api/endpoints.txt") --argfile graphql <(jq -R . "$WORK_DIR/api/graphql.txt") --argfile openapi <(jq -R . "$WORK_DIR/api/openapi.txt") '{endpoints:$endpoints, graphql:$graphql, openapi:$openapi}' > "$WORK_DIR/api/api.json"

    local ENDPOINTS
    local GRAPHQL
    local OPENAPI
    ENDPOINTS=$(wc -l < "$WORK_DIR/api/endpoints.txt")
    GRAPHQL=$(wc -l < "$WORK_DIR/api/graphql.txt")
    OPENAPI=$(wc -l < "$WORK_DIR/api/openapi.txt")
    log_success "API completed (${ENDPOINTS} endpoints, ${GRAPHQL} graphql, ${OPENAPI} openapi)"
}