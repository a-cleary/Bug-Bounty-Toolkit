#!/usr/bin/env bash

set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(pwd)"

export FRAMEWORK_DIR
export WORK_DIR

source "$FRAMEWORK_DIR/lib/cli.sh"

parse_args "$@"

source "$FRAMEWORK_DIR/lib/bootstrap.sh"

echo "[+] Recon Framework"

validate_all
initialize_metadata
load_scope
index_modules
build_execution_plan

if run_pipeline
then
    finalize_metadata completed
    log_success "Recon completed"
else
    finalize_metadata failed
    log_error "Recon failed"
    exit 1
fi