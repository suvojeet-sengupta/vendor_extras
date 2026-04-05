#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/apps"

[ ! -d "$TARGET_DIR" ] && echo "[!] ERROR: $TARGET_DIR not found" && exit 1

echo "[*] Scanning..."

split_count=0
skip_count=0

while IFS= read -r apk; do
    size_bytes=$(stat -c %s "$apk")
    size_mb=$(( size_bytes / 1024 / 1024 ))

    if [ "$size_bytes" -gt $((30 * 1024 * 1024)) ]; then
        echo "[+] Splitting: $apk (${size_mb}MB)"

        if ls "$apk.part"* 1>/dev/null 2>&1; then
            echo "[!] Old parts found, cleaning..."
            rm -f "$apk.part"* "$apk.hash" "$apk.perm"
        fi

        perm=$(stat -c %a "$apk")

        if ! split -b 20M -d -a 2 "$apk" "$apk.part"; then
            echo "[✗] Split failed: $apk"
            rm -f "$apk.part"*
            continue
        fi

        (cd "$(dirname "$apk")" && sha256sum "$(basename "$apk").part"*) > "$apk.hash"

        rm -f "$apk"
        echo "$perm" > "$apk.perm"

        split_count=$((split_count+1))
    else
        echo "[-] Skipped: $apk (${size_mb}MB, under 30MB threshold)"
        skip_count=$((skip_count+1))
    fi

done < <(find "$TARGET_DIR" -type f -name "*.apk")

echo ""
if [ "$split_count" -gt 0 ]; then
    echo "[✓] Done ($split_count split, $skip_count skipped)"
elif [ "$skip_count" -gt 0 ]; then
    echo "[!] Nothing split ($skip_count under threshold)"
else
    echo "[!] No APK found"
fi
