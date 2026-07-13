#!/usr/bin/env bash

CONFIG_FILE_OVERRIDE=""
ONLY_MODULE=""
SKIP_MODULES=()
RESUME=false
DRY_RUN=false
VERBOSE=false

usage() {
    cat <<EOF

Usage:

$0 [options]


Options:

    --config <file>
        Custom configuration file

    --resume
        Resume previously completed modules

    --only <module>
        Run only the specified module

    --skip <module>
        Skip the specified module

    --dry-run
        Build and display the execution plan without running modules

    --verbose
        Enable verbose logging

    -h, --help
        Show this help message


Examples:

    $0

    $0 --resume

    $0 --only HTTP

    $0 --skip NUCLEI

    $0 --scope /home/user/Targets/example/scope

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]
    do
        case "$1" in
            --config)
                [[ $# -ge 2 ]] || {
                    echo "Missing argument for --config"
                    exit 1
                }
                CONFIG_FILE_OVERRIDE="$2"
                shift 2
                ;;

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

            --verbose)
                VERBOSE=true
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
    export VERBOSE
}