#!/usr/bin/env bash

collect_versions() {
    mkdir -p "$WORK_DIR/meta"
    local VERSION_FILE="$WORK_DIR/meta/tools.txt"
    echo "# Tool Versions" > "$VERSION_FILE"

    local TOOLS=(
        subfinder
        amass
        dnsx
        httpx
        katana
        gau
        waybackurls
        nuclei
        naabu
        nmap
    )

    for tool in "${TOOLS[@]}"
    do
        if command -v "$tool" >/dev/null 2>&1
        then
            echo "" >> "$VERSION_FILE"
            echo "## $tool" >> "$VERSION_FILE"
            "$tool" -version 2>/dev/null >> "$VERSION_FILE" || true
        else
            echo "## $tool (missing)" >> "$VERSION_FILE"
        fi
    done
    echo "[+] Versions saved"
}