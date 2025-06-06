#!/bin/bash
set -e

LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

check_paru() {
    if ! command -v paru >/dev/null 2>&1; then
        echo "[ERROR] paru is not installed. Please install paru first." >&2
        exit 1
    fi
}

run_cmd() {
    if $DRY_RUN; then
        echo "DRY RUN: $*"
    else
        "$@"
    fi
}

DRY_RUN=false
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done
set -- "${POSITIONAL[@]}"

echo "[XanadOS] Starting Gaming Stack installation at $(date)"

usage() {
    echo "Usage: $0 [-f package_file] [packages...]" >&2
}

PACKAGES=()
while getopts ":f:h" opt; do
    case $opt in
        f)
            if [[ -f $OPTARG ]]; then
                while IFS= read -r line; do
                    [[ -z $line || $line =~ ^# ]] && continue
                    PACKAGES+=("$line")
                done < "$OPTARG"
            else
                echo "[ERROR] Package file not found: $OPTARG" >&2
                exit 1
            fi
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

check_paru

if [[ $# -gt 0 ]]; then
    PACKAGES+=("$@")
fi

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    PACKAGES=(steam lutris heroic-games-launcher gamemode mangohud vkbasalt protontricks)
fi

if ! run_cmd paru -Syu --needed --noconfirm "${PACKAGES[@]}"; then
    echo "[ERROR] Gaming Stack installation failed."
    exit 1
fi

echo "[XanadOS] Gaming tools installed successfully at $(date)"
