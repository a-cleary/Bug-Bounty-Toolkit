#!/usr/bin/env bash

run_module() {
    source "$MODULE"

    if declare -f module_before >/dev/null
    then
        module_before "$TARGET"
    fi

    module_run "$TARGET"

    if declare -f module_after >/dev/null
    then
        module_after "$TARGET"
    fi
}