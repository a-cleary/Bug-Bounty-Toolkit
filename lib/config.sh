#!/usr/bin/env bash

CONFIG_FILE="${FRAMEWORK_DIR}/config.yaml"

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]
    then
        log_warn "Missing config.yaml"
        return 1
    fi

    CONFIG_THREADS_DEFAULT=$(yq '.threads.default' "$CONFIG_FILE")
    CONFIG_HTTPX_THREADS=$(yq '.threads.httpx' "$CONFIG_FILE")
    CONFIG_KATANA_THREADS=$(yq '.threads.katana' "$CONFIG_FILE")
    CONFIG_NUCLEI_THREADS=$(yq '.threads.nuclei' "$CONFIG_FILE")
    CONFIG_JS_THREADS=$(yq '.threads.javascript' "$CONFIG_FILE")
    CONFIG_CURL_TIMEOUT=$(yq '.timeouts.curl' "$CONFIG_FILE")
    CONFIG_HTTPX_TIMEOUT=$(yq '.timeouts.httpx' "$CONFIG_FILE")
    CONFIG_KATANA_DEPTH=$(yq '.depth.katana' "$CONFIG_FILE")
    CONFIG_TOP_PORTS=$(yq '.ports.top_ports' "$CONFIG_FILE")
    FEATURE_SCREENSHOTS=$(yq '.features.screenshots' "$CONFIG_FILE")
    FEATURE_WAF=$(yq '.features.waf_detection' "$CONFIG_FILE")
    FEATURE_NUCLEI=$(yq '.features.nuclei' "$CONFIG_FILE")
    FEATURE_PORTS=$(yq '.features.ports' "$CONFIG_FILE")
    FEATURE_JS=$(yq '.features.javascript' "$CONFIG_FILE")
    FEATURE_CLOUD=$(yq '.features.cloud' "$CONFIG_FILE")
    LINKFINDER_PATH=$(yq '.tools.linkfinder' "$CONFIG_FILE")
    SECRETFINDER_PATH=$(yq '.tools.secretfinder' "$CONFIG_FILE")
    OUTPUT_PATH=$(yq '.paths.output' "$CONFIG_FILE")
    CACHE_PATH=$(yq '.paths.cache' "$CONFIG_FILE")

    export \
        CONFIG_THREADS_DEFAULT \
        CONFIG_HTTPX_THREADS \
        CONFIG_KATANA_THREADS \
        CONFIG_NUCLEI_THREADS \
        CONFIG_JS_THREADS \
        CONFIG_CURL_TIMEOUT \
        CONFIG_HTTPX_TIMEOUT \
        CONFIG_KATANA_DEPTH \
        CONFIG_TOP_PORTS \
        FEATURE_SCREENSHOTS \
        FEATURE_WAF \
        FEATURE_NUCLEI \
        FEATURE_PORTS \
        FEATURE_JS \
        FEATURE_CLOUD \
        LINKFINDER_PATH \
        SECRETFINDER_PATH \
        OUTPUT_PATH \
        CACHE_PATH
}