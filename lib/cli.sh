#!/usr/bin/env bash

CONFIG_FILE_OVERRIDE=""
ONLY_MODULE=""
SKIP_MODULES=()
RESUME=false
DRY_RUN=false

usage() {
    local PROG
    PROG="$(basename "$0")"
    cat <<EOF

Usage:

${PROG} [options]


Options:

    --resume
        Resume previously completed modules

    --only <module>
        Run only the specified module

    --skip <module>
        Skip the specified module

    --dry-run
        Build and display the execution plan without running modules

    -h, --help
        Show this help message


Examples:

    ${PROG}

    ${PROG} --resume

    ${PROG} --only HTTP

    ${PROG} --skip NUCLEI

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]
    do
        case "$1" in
            --resume)
                RESUME=true
                shift
                ;;

            --only)
                [[ $# -ge 2 ]] || {
                    echo "Missing argument for --only"
                    exit 1
                }
                ONLY_MODULE="${2^^}"
                shift 2
                ;;

            --skip)
                [[ $# -ge 2 ]] || {
                    echo "Missing argument for --skip"
                    exit 1
                }
                SKIP_MODULES+=("${2^^}")
                shift 2
                ;;

            --dry-run)
                DRY_RUN=true
                shift
                ;;

            -h|--help)
                usage
                exit 0
                ;;

            *)
                echo "Unknown argument: $1"
                echo
                usage
                exit 1
                ;;

        esac
    done

    export CONFIG_FILE_OVERRIDE
    export ONLY_MODULE
    export RESUME
    export DRY_RUN
}