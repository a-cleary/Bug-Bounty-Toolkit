#!/usr/bin/env bash

run_subfinder() {
    local DOMAIN="$1"
    local OUTPUT="$2"

    subfinder -d "$DOMAIN" -silent -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_amass() {
    local DOMAIN="$1"
    local OUTPUT="$2"

    amass enum -d "$DOMAIN" -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_alterx() {
    local INPUT="$1"
    local OUTPUT="$2"

    alterx -l "$INPUT" -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_dnsx() {
    local INPUT="$1"
    local OUTPUT="$2"

    dnsx -l "$INPUT" -json -a -aaaa -cname -mx -ns -txt -silent -threads "$CONFIG_DNSX_THREADS" -o "$OUTPUT" >/dev/null 2>&1

    if [[ $? -ne 0 ]]
    then
        log_error "dnsx execution failed"
        return 1
    fi

    if [[ ! -s "$OUTPUT" ]]
    then
        log_warn "dnsx produced no output"
        return 1
    fi
}

run_httpx() {
    local INPUT="$1"
    local OUTPUT="$2"

    httpx -l "$INPUT" -json -silent -title -tech-detect -status-code -content-length -web-server -follow-redirects -threads "$CONFIG_HTTPX_THREADS" -timeout "$CONFIG_HTTPX_TIMEOUT" -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_waybackurls() {
    local DOMAIN="$1"
    local OUTPUT="$2"

    waybackurls "$DOMAIN" > "$OUTPUT" 2>/dev/null || true
}

run_gau() {
    local DOMAIN="$1"
    local OUTPUT="$2"

    gau "$DOMAIN" > "$OUTPUT" 2>/dev/null || true
}

run_katana() {
    local INPUT="$1"
    local OUTPUT="$2"

    katana -list "$INPUT" -silent -jc -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_naabu() {
    local INPUT="$1"
    local OUTPUT="$2"

    naabu -list "$INPUT" -silent -rate "$CONFIG_NAABU_RATE" -o "$OUTPUT" >/dev/null 2>&1 || true
}

run_nuclei() {
    local INPUT="$1"
    local OUTPUT="$2"

    nuclei -l "$INPUT" -silent -jsonl -rate-limit "$CONFIG_NUCLEI_RATE" -concurrency "$CONFIG_NUCLEI_THREADS" -o "$OUTPUT" >/dev/null 2>&1 || true
}