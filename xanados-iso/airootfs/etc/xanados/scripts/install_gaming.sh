#!/bin/bash
set -e

LOGFILE="/tmp/welcome_install.log"
exec > >(tee -a "$LOGFILE") 2>&1

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

if [[ $# -gt 0 ]]; then
    PACKAGES+=("$@")
fi

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    PACKAGES=(steam lutris heroic-games-launcher gamemode mangohud vkbasalt protontricks)
fi

if ! paru -Syu --needed --noconfirm "${PACKAGES[@]}"; then
    echo "[ERROR] Gaming Stack installation failed."
    exit 1
fi

echo "[XanadOS] Gaming tools installed successfully at $(date)"
