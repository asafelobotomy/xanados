#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_ROOT="$REPO_ROOT/packages"
REPO_DIR="$PKG_ROOT/repo"

mkdir -p "$REPO_DIR"

# Silence systemd warnings in CI by ensuring /etc/machine-id exists
if [ ! -f /etc/machine-id ]; then
  sudo systemd-machine-id-setup >/dev/null
fi

# Run command as root, using sudo if needed
as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

# Run command as the dedicated build user when executed as root
as_builduser() {
  if ((EUID == 0)); then
    sudo -Hu builduser "$@"
  else
    "$@"
  fi
}

if ((EUID == 0)); then
  # Create build user if missing
  if ! id builduser >/dev/null 2>&1; then
    as_root useradd -m builduser
  fi
fi

install_deps() {
  local dir="$1"
  pushd "$dir" >/dev/null
  # shellcheck disable=SC1091
  source ./PKGBUILD
  local all_deps=("${depends[@]}")
  all_deps+=("${makedepends[@]}")
  if [ ${#all_deps[@]} -gt 0 ]; then
    local missing
    missing=$(pacman -T "${all_deps[@]}" || true)
    if [ -n "$missing" ]; then
      echo "Installing missing dependencies: $missing"
      as_root pacman -Sy --needed --noconfirm "$missing"

    fi
  fi
  popd >/dev/null
}

build_pkg() {
  local dir="$1"
  if [ ! -f "$dir/PKGBUILD" ]; then
    return
  fi
  echo "## Building $(basename "$dir")"
  pushd "$dir" >/dev/null
  if ! command -v namcap >/dev/null 2>&1; then
    echo "Installing namcap" >&2
    as_root pacman -Sy --needed --noconfirm namcap
  fi
  as_builduser namcap PKGBUILD || true
  as_builduser makepkg --verifysource --noconfirm
  as_builduser updpkgsums
  install_deps "$dir"
  as_builduser makepkg -f --noconfirm
  local pkgfile
  pkgfile=$(find . -maxdepth 1 -name '*.pkg.tar.zst' -print -quit)
  if [ -n "${pkgfile:-}" ]; then
    mv "$pkgfile" "$REPO_DIR/"
    if [[ $(basename "$dir") == "bats" ]]; then
      echo "Installing $(basename "$pkgfile")"
      as_root pacman -U --noconfirm "$REPO_DIR/$(basename "$pkgfile")"
    fi
  fi
  popd >/dev/null
}

for pkg in "$PKG_ROOT"/*; do
  [ "$(basename "$pkg")" = "repo" ] && continue
  [ -d "$pkg" ] && build_pkg "$pkg"
done
