#!/usr/bin/env bash

set -euo pipefail

#############
# Variables #
#############
API_DIR="api"

ALL_URLS="content/all_urls.txt"
JS_ENDPOINTS="content/js_endpoints.txt"
LIVE_HOSTS="discovery/live_hosts.txt"

GRAPHQL="${API_DIR}/graphql.txt"
LIVE_GRAPHQL="${API_DIR}/live_graphql.txt"

SWAGGER="${API_DIR}/swagger.txt"
OPENAPI="${API_DIR}/openapi.txt"
POSTMAN="${API_DIR}/postman.txt"

API_HOSTS="${API_DIR}/api_hosts.txt"

API_PATHS="${API_DIR}/api_paths.txt"

ENDPOINTS="${API_DIR}/endpoints.txt"
LIVE_ENDPOINTS="${API_DIR}/live_endpoints.txt"
LIVE_ENDPOINTS_JSON="${API_DIR}/live_endpoints.json"

LIVE_DOCS="${API_DIR}/live_docs.txt"
API_INVENTORY="${API_DIR}/api_inventory.txt"


###########
# Logging #
###########
info()    { echo "[*] $*"; }
success() { echo "[+] $*"; }
error()   { echo "[-] $*" >&2; }

count_lines() {
    [[ -f "$1" ]] && wc -l < "$1" || echo 0
}


################
# Requirements #
################
check_requirements() {
    local bins=(httpx curl jq)
    for bin in "${bins[@]}"
    do
        command -v "$bin" >/dev/null 2>&1 || {
            error "$bin not found"
            exit 1
        }
    done
}


####################
# Common API Paths #
####################
create_api_paths() {
    cat > "$API_PATHS" <<EOF
/graphql
/graphiql

/swagger
/swagger-ui
/swagger-ui.html
/swagger.json

/openapi.json
/openapi.yaml

/api
/api/v1
/api/v2

/api-docs
/docs
/redoc

/postman
/postman.json
EOF
}


#######################
# Discovery From URLs #
#######################
discover_graphql() {
    grep -hEi '/graphql|/graphiql' "$ALL_URLS" "$JS_ENDPOINTS" 2>/dev/null | sort -u > "$GRAPHQL" || true
}

discover_swagger() {
    grep -hEi 'swagger|swagger-ui|swagger\.json' "$ALL_URLS" "$JS_ENDPOINTS" 2>/dev/null | sort -u > "$SWAGGER" || true
}

discover_openapi() {
    grep -hEi 'openapi\.json|openapi\.yaml|api-docs|redoc' "$ALL_URLS" "$JS_ENDPOINTS" 2>/dev/null | sort -u > "$OPENAPI" || true
}

discover_postman() {
    grep -hEi 'postman' "$ALL_URLS" "$JS_ENDPOINTS" 2>/dev/null | sort -u > "$POSTMAN" || true
}


######################
# API Host Discovery #
######################
discover_api_hosts() {
    grep -Ei 'api|apis|gateway|backend|graphql|rest|rpc|service|services|microservice|internal-api|partner-api' "$LIVE_HOSTS" 2>/dev/null | sort -u > "$API_HOSTS" || true
}


################################
# Generate Candidate Endpoints #
################################
generate_common_endpoints() {
    [[ -s "$LIVE_HOSTS" ]] || return 0
    while read -r host
    do
        host="${host%/}"
        while read -r path
        do
            [[ -z "$path" ]] && continue
            echo "${host}${path}"
        done < "$API_PATHS"
    done < "$LIVE_HOSTS"
}


#######################
# Build Endpoint List #
#######################
build_endpoint_list() {
    {
        cat "$GRAPHQL" 2>/dev/null
        cat "$SWAGGER" 2>/dev/null
        cat "$OPENAPI" 2>/dev/null
        cat "$POSTMAN" 2>/dev/null
        generate_common_endpoints
    } | sort -u > "$ENDPOINTS"
}


######################
# Validate Endpoints #
######################
validate_endpoints() {
    [[ -s "$ENDPOINTS" ]] || return 0
    httpx -silent -json -title -tech-detect -status-code -l "$ENDPOINTS" > "$LIVE_ENDPOINTS_JSON" || true
    jq -r '.url // empty' "$LIVE_ENDPOINTS_JSON" 2>/dev/null | sort -u > "$LIVE_ENDPOINTS"
}


######################
# GraphQL Validation #
######################
validate_graphql() {
    : > "$LIVE_GRAPHQL"
    [[ -s "$GRAPHQL" ]] || return 0
    while read -r endpoint
    do
        response="$(curl -sk -X POST -H 'Content-Type: application/json' -d '{"query":"{__typename}"}' "$endpoint" 2>/dev/null || true)"
        [[ "$response" =~ __typename|errors|data ]] && echo "$endpoint" >> "$LIVE_GRAPHQL"
    done < "$GRAPHQL"
    sort -u "$LIVE_GRAPHQL" -o "$LIVE_GRAPHQL"
}


################################
# OpenAPI / Swagger Validation #
################################
validate_docs() {
    : > "$LIVE_DOCS"
    {
        cat "$SWAGGER" 2>/dev/null
        cat "$OPENAPI" 2>/dev/null
    } | sort -u |
    while read -r url
    do
        headers="$(curl -skI "$url" 2>/dev/null || true)"
        echo "$headers" | grep -qi 'application/json' && echo "$url"
    done | sort -u > "$LIVE_DOCS"
}


#################
# API Inventory #
#################
build_inventory() {
    : > "$API_INVENTORY"
    while read -r host
    do
        echo "${host},hostname"
    done < "$API_HOSTS" >> "$API_INVENTORY"

    while read -r endpoint
    do
        echo "${endpoint},endpoint"
    done < "$LIVE_ENDPOINTS" >> "$API_INVENTORY"

    while read -r endpoint
    do
        echo "${endpoint},graphql"
    done < "$LIVE_GRAPHQL" >> "$API_INVENTORY"

    while read -r endpoint
    do
        echo "${endpoint},api-doc"
    done < "$LIVE_DOCS" >> "$API_INVENTORY"

    sort -u "$API_INVENTORY" -o "$API_INVENTORY"
}


###########
# Summary #
###########
summary() {
    echo
    echo "========== API SUMMARY =========="
    echo
    echo "GraphQL Candidates : $(count_lines "$GRAPHQL")"
    echo "Live GraphQL       : $(count_lines "$LIVE_GRAPHQL")"
    echo "Swagger            : $(count_lines "$SWAGGER")"
    echo "OpenAPI            : $(count_lines "$OPENAPI")"
    echo "Postman            : $(count_lines "$POSTMAN")"
    echo "API Hosts          : $(count_lines "$API_HOSTS")"
    echo "Endpoints          : $(count_lines "$ENDPOINTS")"
    echo "Live Endpoints     : $(count_lines "$LIVE_ENDPOINTS")"
    echo "Live API Docs      : $(count_lines "$LIVE_DOCS")"
    echo "Inventory Entries  : $(count_lines "$API_INVENTORY")"
    echo
}


########
# Main #
########
main() {
    check_requirements
    create_api_paths
    discover_graphql
    discover_swagger
    discover_openapi
    discover_postman
    discover_api_hosts
    build_endpoint_list
    validate_endpoints
    validate_graphql
    validate_docs
    build_inventory
    summary
}

main "$@"