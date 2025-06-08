#!/usr/bin/env bash
set -euo pipefail

# Build the local package repository from compressed AUR archives.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/repo"
# Temporary working directory for extracting and building packages
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[INFO] Building packages into $REPO_DIR" >&2

shopt -s nullglob
for archive in "$REPO_DIR"/*.tar.gz "$REPO_DIR"/*.zip; do
    [ -e "$archive" ] || continue
    pkgdir="$TMP_DIR/$(basename "${archive%.*.*}")"
    mkdir -p "$pkgdir"
    case "$archive" in
        *.tar.gz)
            tar -xzf "$archive" -C "$pkgdir" ;;
        *.zip)
            unzip -q "$archive" -d "$pkgdir" ;;
    esac
    echo "[INFO] Extracted $archive" >&2
    if [[ -f "$pkgdir/PKGBUILD" ]]; then
        echo "[INFO] Building $(basename "$archive")" >&2
        (cd "$pkgdir" && makepkg -s --noconfirm --noprogressbar)
    fi
done
shopt -u nullglob

# Move any built packages from the temp directory back to the repo
if ls "$TMP_DIR"/*.pkg.tar.* "$TMP_DIR"/*/*.pkg.tar.* >/dev/null 2>&1; then
    mv "$TMP_DIR"/*/*.pkg.tar.* "$REPO_DIR"/ 2>/dev/null || true
    mv "$TMP_DIR"/*.pkg.tar.* "$REPO_DIR"/ 2>/dev/null || true
fi

cd "$REPO_DIR"
if ls ./*.pkg.tar.zst >/dev/null 2>&1; then
    repo-add -q xanados.db.tar.gz ./*.pkg.tar.zst
    repo-add -q xanados.files.tar.gz ./*.pkg.tar.zst
    echo "[INFO] Repository database updated" >&2
else
    echo "[WARN] No package files found" >&2
fi
