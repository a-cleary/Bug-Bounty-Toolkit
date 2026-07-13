#!/usr/bin/env bash

set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"
export FRAMEWORK_DIR
export WORK_DIR

ONLY_MODULE="${ONLY_MODULE:-}"
export ONLY_MODULE

source "$FRAMEWORK_DIR/lib/bootstrap.sh"

parse_args "$@"

echo "[+] Recon Framework"

validate_all
initialize_state
initialize_metadata

load_scope

index_modules
build_execution_plan

if [[ "$DRY_RUN" == true ]]
then
    log_info "Dry run complete"
    exit 0
fi 

if run_pipeline
then
    finalize_metadata completed
    log_success "Recon completed"
else
    finalize_metadata failed
    log_error "Recon failed"
    exit 1
fi