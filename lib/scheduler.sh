#!/usr/bin/env bash

MODULE_DIR="$FRAMEWORK_DIR/modules"

declare -a MODULE_FILES
declare -a EXECUTION_PLAN

index_modules() {
    MODULE_FILES=()
    while IFS= read -r MODULE
    do
        MODULE_FILES+=("$MODULE")
    done < <(find "$MODULE_DIR" -maxdepth 1 -type f -name "*.sh" | sort)

    if [[ "${#MODULE_FILES[@]}" -eq 0 ]]
    then
        log_error "No modules found"
        exit 1
    fi

    log_success "Indexed ${#MODULE_FILES[@]} modules"
}

build_execution_plan() {
    EXECUTION_PLAN=()
    for MODULE in "${MODULE_FILES[@]}"
    do
        local NAME
        NAME=$(basename "$MODULE")
        if [[ -n "${ONLY_MODULE:-}" ]]
        then
            if [[ "$NAME" != "$ONLY_MODULE" ]]
            then
                continue
            fi
        fi

        EXECUTION_PLAN+=("$MODULE")
    done

    if [[ "${#EXECUTION_PLAN[@]}" -eq 0 ]]
    then
        log_error "No modules selected"
        exit 1
    fi

    log_success "Execution plan created (${#EXECUTION_PLAN[@]} modules)"
}

run_pipeline() {
    for MODULE_PATH in "${EXECUTION_PLAN[@]}"
    do
        if ! run_module "$MODULE_PATH"
        then
            return 1
        fi
    done

    generate_artifact_index
    return 0
}

run_module() {
    local MODULE_PATH="$1"
    local MODULE_FILE

    MODULE_FILE="$(basename "$MODULE_PATH")"

    local MODULE_ID
    MODULE_ID=$(echo "$MODULE_FILE" | cut -d'_' -f1)

    unset MODULE_NAME
    unset MODULE_DESCRIPTION
    unset MODULE_OUTPUTS

    source "$MODULE_PATH"

    if [[ -z "${MODULE_NAME:-}" ]]
    then
        MODULE_NAME="UNKNOWN"
    fi

    local DISPLAY_NAME
    DISPLAY_NAME=$(echo "$MODULE_NAME" | tr '[:lower:]' '[:upper:]')

    export CURRENT_MODULE_ID="$MODULE_ID"
    export CURRENT_MODULE_NAME="$DISPLAY_NAME"

    set_module_context "$MODULE_ID" "$DISPLAY_NAME"

    if [[ "${RESUME:-false}" == true ]] && is_module_completed "$MODULE_FILE"
    then
        log_info "Skipping (already completed)"
        return 0
    fi

    log_info "Starting"
    mark_module_started "$MODULE_FILE"

    if module_run
    then
        mark_module_completed "$MODULE_FILE"
        record_module_execution "$MODULE_FILE"
        log_success "Completed"
        return 0
    else
        mark_module_failed "$MODULE_FILE"
        log_error "Failed"
        return 1
    fi
}