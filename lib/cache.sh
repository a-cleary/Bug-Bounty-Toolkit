#!/usr/bin/env bash

cache_exists() {
    local key="$1"
    [[ -f "$CACHE_DIR/$key" ]]
}

cache_write() {
    local key="$1"
    local file="$2"
    cp "$file" "$CACHE_DIR/$key"
}

cache_restore() {
    local key="$1"
    local output="$2"
    cp "$CACHE_DIR/$key" "$output"
}