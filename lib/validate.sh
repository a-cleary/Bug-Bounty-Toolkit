#!/usr/bin/env bash

validate_framework() {
    local REQUIRED_DIRS=(
        "$FRAMEWORK_DIR/lib"
        "$FRAMEWORK_DIR/modules"
    )

    for DIR in "${REQUIRED_DIRS[@]}"
    do
        if [[ ! -d "$DIR" ]]
        then
            log_error "Missing framework directory: $DIR"
            return 1
        fi
    done


    log_success "Framework structure validated"
}

validate_scope() {
    local REQUIRED_FILES=(
        "$WORK_DIR/scope/known_subdomains.txt"
        "$WORK_DIR/scope/wildcard_domains.txt"
        "$WORK_DIR/scope/out_of_scope.txt"
    )

    for FILE in "${REQUIRED_FILES[@]}"
    do
        if [[ ! -f "$FILE" ]]
        then
            log_error "Missing scope file: $FILE"
            return 1
        fi
    done

    log_success "Scope files validated"
}

validate_tools() {
    local REQUIRED_TOOLS=(
        jq
        yq
    )
    local MISSING=()

    for TOOL in "${REQUIRED_TOOLS[@]}"
    do
        if ! command -v "$TOOL" >/dev/null 2>&1
        then
            MISSING+=("$TOOL")
        fi
    done

    if [[ "${#MISSING[@]}" -gt 0 ]]
    then
        log_error "Missing required tools: ${MISSING[*]}"
        return 1
    fi

    log_success "Required tools validated"
}

validate_functions() {
    local FUNCTIONS=(
        load_scope
        index_modules
        build_execution_plan
        run_pipeline
        generate_artifact_index
    )

    for FUNCTION in "${FUNCTIONS[@]}"
    do
        if ! declare -F "$FUNCTION" >/dev/null
        then
            log_error "Missing required function: $FUNCTION"
            return 1
        fi
    done

    log_success "Framework functions validated"
}

validate_workdir() {
    if [[ ! -d "$WORK_DIR" ]]
    then
        log_error "Work directory does not exist: $WORK_DIR"
        return 1
    fi

    if [[ "$WORK_DIR" == "$FRAMEWORK_DIR" ]]
    then
        log_warn "Running inside framework directory"
    fi

    log_success "Work directory validated"
}

validate_all() {
    validate_framework || return 1
    validate_scope || return 1
    validate_tools || return 1
    validate_functions || return 1
    validate_workdir || return 1
}