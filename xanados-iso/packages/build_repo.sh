#!/usr/bin/env bash
set -euo pipefail

# Build the local package repository from compressed archives.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/repo"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[INFO] Extracting packages to $REPO_DIR" >&2

shopt -s nullglob
for archive in "$REPO_DIR"/*.tar.gz "$REPO_DIR"/*.zip; do
    [ -e "$archive" ] || continue
    case "$archive" in
        *.tar.gz)
            tar -xzf "$archive" -C "$TMP_DIR" ;;
        *.zip)
            unzip -q "$archive" -d "$TMP_DIR" ;;
    esac
    echo "[INFO] Processed $archive" >&2
done
shopt -u nullglob

if ls "$TMP_DIR"/*.pkg.tar.* >/dev/null 2>&1; then
    mv "$TMP_DIR"/*.pkg.tar.* "$REPO_DIR"/
fi

cd "$REPO_DIR"
if ls ./*.pkg.tar.zst >/dev/null 2>&1; then
    repo-add -q xanados.db.tar.gz ./*.pkg.tar.zst
    repo-add -q xanados.files.tar.gz ./*.pkg.tar.zst
    echo "[INFO] Repository database updated" >&2
else
    echo "[WARN] No package files found" >&2
fi
