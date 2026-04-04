#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/apps"

[ ! -d "$TARGET_DIR" ] && echo "[!] ERROR: $TARGET_DIR not found" && exit 1

echo "[*] Verifying & merging..."

merged=0
skipped=0

for part0 in $(find "$TARGET_DIR" -type f -name "*.apk.part00"); do
base="${part0%.part00}"

echo "[*] Checking: $base"

if [ ! -f "$base.hash" ]; then
    echo "[!] Missing hash: $base"
    skipped=$((skipped+1))
    continue
fi

(cd "$(dirname "$base")" && sha256sum -c "$(basename "$base").hash") > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[✗] Corrupt/missing parts: $base"
    skipped=$((skipped+1))
    continue
fi

if [ -f "$base" ]; then
    echo "[!] APK already exists: $base"
    skipped=$((skipped+1))
    continue
fi

echo "[+] Merging: $base"
cat "${base}.part"* > "$base"

[ -f "$base.perm" ] && chmod "$(cat "$base.perm")" "$base" && rm -f "$base.perm"

rm -f "${base}.part"* "$base.hash"

merged=$((merged+1))

done

if [ "$merged" -gt 0 ]; then
echo "[✓] Done ($merged merged, $skipped skipped)"
elif [ "$skipped" -gt 0 ]; then
echo "[✗] No merge done ($skipped skipped)"
else
echo "[!] Nothing to merge"
fi
