#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/apps"

[ ! -d "$TARGET_DIR" ] && echo "[!] ERROR: $TARGET_DIR not found" && exit 1

echo "[*] Verifying & merging..."

merged=0
corrupt=0
already_done=0

while IFS= read -r part0; do
    base="${part0%.part00}"

    echo "[*] Checking: $base"

    if [ ! -f "$base.hash" ]; then
        echo "[!] Missing hash: $base"
        corrupt=$((corrupt+1))
        continue
    fi

    if ! (cd "$(dirname "$base")" && sha256sum -c "$(basename "$base").hash" > /dev/null 2>&1); then
        echo "[✗] Corrupt/missing parts: $base"
        corrupt=$((corrupt+1))
        continue
    fi

    if [ -f "$base" ]; then
        echo "[✓] Already merged: $base"
        already_done=$((already_done+1))
        continue
    fi

    echo "[+] Merging: $base"
    if ! cat "${base}.part"* > "$base"; then
        echo "[✗] Merge failed: $base"
        rm -f "$base"
        corrupt=$((corrupt+1))
        continue
    fi

    if [ -f "$base.perm" ]; then
        chmod "$(cat "$base.perm")" "$base" && rm -f "$base.perm"
    fi

    rm -f "${base}.part"* "$base.hash"

    merged=$((merged+1))

done < <(find "$TARGET_DIR" -type f -name "*.apk.part00")

echo ""
[ "$merged"       -gt 0 ] && echo "[✓] Merged:        $merged"
[ "$already_done" -gt 0 ] && echo "[✓] Already done:  $already_done"
[ "$corrupt"      -gt 0 ] && echo "[✗] Failed/corrupt: $corrupt"
[ "$merged" -eq 0 ] && [ "$already_done" -eq 0 ] && [ "$corrupt" -eq 0 ] && echo "[!] Nothing to merge"

[ "$corrupt" -gt 0 ] && exit 1
exit 0
