#!/usr/bin/env bash

load_modules() {
    local dir="$1"
    MODULES=()
    while read -r module
    do
        MODULES+=("$module")
    done < <(find "$dir" -name "*.sh" | sort)
}

run_module(){
    local module="$1"
    local target="$2"
    source "$module"
    module_run "$target"
}