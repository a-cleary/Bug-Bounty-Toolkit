#!/usr/bin/env bash

if [[ -z "${FRAMEWORK_DIR:-}" ]]
then
    echo "[!] FRAMEWORK_DIR not set"
    exit 1
fi

source "$FRAMEWORK_DIR/lib/defaults.sh"
source "$FRAMEWORK_DIR/lib/logger.sh"
source "$FRAMEWORK_DIR/lib/artifacts.sh"
source "$FRAMEWORK_DIR/lib/state.sh"
source "$FRAMEWORK_DIR/lib/tools.sh"
source "$FRAMEWORK_DIR/lib/dependencies.sh"
source "$FRAMEWORK_DIR/lib/scope.sh"
source "$FRAMEWORK_DIR/lib/scheduler.sh"
source "$FRAMEWORK_DIR/lib/metadata.sh"
source "$FRAMEWORK_DIR/lib/validate.sh"
source "$FRAMEWORK_DIR/lib/cli.sh"

initialize_logger
initialize_state
initialize_metadata

require_function() {
    local FUNCTION="$1"
    if ! declare -F "$FUNCTION" >/dev/null
    then
        log_error "Missing required function: $FUNCTION"
        exit 1
    fi
}

require_function load_scope
require_function index_modules
require_function build_execution_plan
require_function run_pipeline
require_function generate_artifact_index
