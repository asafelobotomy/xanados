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
REMOVE=false
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	case $1 in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--remove)
		REMOVE=true
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
	echo "Usage: $0 [--remove] [--dry-run] [-f package_file] [packages...]" >&2
}

PACKAGES=()
while getopts ":f:h" opt; do
	case $opt in
	f)
		if [[ -f $OPTARG ]]; then
			while IFS= read -r line; do
				[[ -z $line || $line =~ ^# ]] && continue
				PACKAGES+=("$line")
			done <"$OPTARG"
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
shift $((OPTIND - 1))

check_paru

if [[ $# -gt 0 ]]; then
	PACKAGES+=("$@")
fi

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
	PACKAGES=(steam lutris heroic-games-launcher gamemode mangohud vkbasalt protontricks)
fi

FINAL_PKGS=()
if $REMOVE; then
	for pkg in "${PACKAGES[@]}"; do
		if pacman -Qq "$pkg" >/dev/null 2>&1; then
			FINAL_PKGS+=("$pkg")
		else
			echo "[INFO] Package not installed: $pkg"
		fi
	done
	if [[ ${#FINAL_PKGS[@]} -eq 0 ]]; then
		echo "[INFO] No packages to remove."
		exit 0
	fi
	echo "[XanadOS] Packages to remove: ${FINAL_PKGS[*]}"
	if ! run_cmd paru -Rns --noconfirm "${FINAL_PKGS[@]}"; then
		echo "[ERROR] Gaming Stack removal failed."
		exit 1
	fi
	echo "[XanadOS] Gaming tools removed successfully at $(date)"
else
	for pkg in "${PACKAGES[@]}"; do
		if pacman -Qq "$pkg" >/dev/null 2>&1; then
			echo "[INFO] Skipping already installed package: $pkg"
		else
			FINAL_PKGS+=("$pkg")
		fi
	done
	if [[ ${#FINAL_PKGS[@]} -eq 0 ]]; then
		echo "[INFO] All selected packages are already installed."
		exit 0
	fi
	echo "[XanadOS] Packages to install: ${FINAL_PKGS[*]}"
	if ! run_cmd paru -Syu --needed --noconfirm "${FINAL_PKGS[@]}"; then
		echo "[ERROR] Gaming Stack installation failed."
		exit 1
	fi
	echo "[XanadOS] Gaming tools installed successfully at $(date)"
fi
