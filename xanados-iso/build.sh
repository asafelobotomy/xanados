#!/usr/bin/env bash
set -euo pipefail

# Default directories
WORK_DIR="work"
OUT_DIR="out"

BOLD=$(tput bold)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 6)
RED=$(tput setaf 1)

usage() {
    cat <<EOF
${BOLD}XanadOS ISO Build Script${RESET}

Usage: $0 [options]

Options:
  -w, --work DIR   Working directory (default: work)
  -o, --out DIR    Output directory (default: out)
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--work)
            WORK_DIR=$2
            shift 2
            ;;
        -o|--out)
            OUT_DIR=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "${RED}Unknown option: $1${RESET}" >&2
            usage
            exit 1
            ;;
    esac
done

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "${RED}Error: mkarchiso not found. Please install archiso.${RESET}" >&2
    exit 1
fi

mkdir -p "$WORK_DIR" "$OUT_DIR"

echo "${BLUE}${BOLD}[XanadOS] Building ISO from profile $PROFILE_DIR...${RESET}"
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"
echo "${GREEN}${BOLD}[XanadOS] Build complete. ISO is in $OUT_DIR${RESET}"
