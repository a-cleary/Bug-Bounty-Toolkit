#!/usr/bin/env bash

LOG_FILE="${WORK_DIR:-.}/logs/recon.log"
CURRENT_MODULE_ID=""
CURRENT_MODULE_NAME=""

initialize_logger() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
}

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_log() {

    local LEVEL="$1"
    local MESSAGE="$2"
    local TIME
    TIME=$(_timestamp)
    local PREFIX=""

    if [[ -n "${CURRENT_MODULE_ID:-}" ]]
    then
        PREFIX="[Module: ${CURRENT_MODULE_ID}][${CURRENT_MODULE_NAME}]"
    fi

    echo "${TIME} [${LEVEL}]${PREFIX} ${MESSAGE}" | tee -a "$LOG_FILE"
}

log_info() {
    _log "INFO" "$1"
}

log_success() {
    _log "SUCCESS" "$1"
}

log_warn() {
    _log "WARN" "$1"
}

log_error() {
    _log "ERROR" "$1"
}

set_module_context() {
    CURRENT_MODULE_ID="$1"
    CURRENT_MODULE_NAME="$2"
}