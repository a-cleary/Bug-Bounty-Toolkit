#!/usr/bin/env bash

MODULE_DIR="$FRAMEWORK_DIR/modules"

declare -a MODULES

index_modules() {
    MODULES=()
    while read -r module
    do
        MODULES+=("$module")
    done < <(find "$MODULE_DIR" -name "*.sh" | sort)

    log_success "Indexed ${#MODULES[@]} modules"
}