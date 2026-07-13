#!/usr/bin/env bash

set -euo pipefail

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FRAMEWORK_DIR
WORK_DIR="$(pwd)"
export WORK_DIR

source "$FRAMEWORK_DIR/lib/environment.sh"
source "$FRAMEWORK_DIR/lib/versions.sh"

echo "[+] Recon Framework Setup"

check_environment
create_framework_structure
collect_versions
create_scope_templates
print_next_steps

echo
echo "[+] Setup complete"