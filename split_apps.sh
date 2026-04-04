#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/apps"

[ ! -d "$TARGET_DIR" ] && echo "[!] ERROR: $TARGET_DIR not found" && exit 1

echo "[*] Scanning..."

split_count=0
skip_count=0

for apk in $(find "$TARGET_DIR" -type f -name "*.apk"); do
size=$(du -m "$apk" | cut -f1)

if [ "$size" -gt 30 ]; then
    echo "[+] Splitting: $apk (${size}MB)"

    if ls "$apk.part"* 1>/dev/null 2>&1; then
        echo "[!] Old parts found, cleaning..."
        rm -f "$apk.part"* "$apk.hash" "$apk.perm"
    fi

    perm=$(stat -c %a "$apk")

    split -b 20M -d "$apk" "$apk.part"
    (cd "$(dirname "$apk")" && sha256sum "$(basename "$apk").part"*) > "$apk.hash"

    rm -f "$apk"
    echo "$perm" > "$apk.perm"

    split_count=$((split_count+1))
else
    echo "[-] Skipped: $apk (${size}MB)"
    skip_count=$((skip_count+1))
fi

done

if [ "$split_count" -gt 0 ]; then
echo "[✓] Done ($split_count split, $skip_count skipped)"
elif [ "$skip_count" -gt 0 ]; then
echo "[!] Nothing split ($skip_count skipped)"
else
echo "[!] No APK found"
fi
