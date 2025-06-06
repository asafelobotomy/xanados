#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_ROOT="$REPO_ROOT/packages"
REPO_DIR="$PKG_ROOT/repo"

mkdir -p "$REPO_DIR"

build_pkg() {
  local dir="$1"
  if [ ! -f "$dir/PKGBUILD" ]; then
    return
  fi
  echo "## Building $(basename "$dir")"
  pushd "$dir" >/dev/null
  namcap PKGBUILD || true
  makepkg --verifysource --noconfirm
  updpkgsums
  makepkg -sf --noconfirm
  local pkgfile
  pkgfile=$(find . -maxdepth 1 -name '*.pkg.tar.zst' -print -quit)
  if [ -n "${pkgfile:-}" ]; then
    mv "$pkgfile" "$REPO_DIR/"
  fi
  popd >/dev/null
}

for pkg in "$PKG_ROOT"/*; do
  [ "$(basename "$pkg")" = "repo" ] && continue
  [ -d "$pkg" ] && build_pkg "$pkg"
done
