#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/var/log/xanados"
mkdir -p "$LOG_DIR"

init_logging() {
    local prefix=${1:-script}
    LOGFILE="$LOG_DIR/${prefix}_$(date +%Y%m%d_%H%M%S).log"
    exec > >(tee -a "$LOGFILE") 2>&1
    echo "[INFO] Log file: $LOGFILE"
}

cleanup() {
    echo "[INFO] Script finished at $(date)"
}
trap cleanup EXIT

check_paru() {
    if ! command -v paru >/dev/null 2>&1; then
        echo "[ERROR] paru is not installed. Please install paru first." >&2
        return 1
    fi
}

run_cmd() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "DRY RUN: $*"
    else
        "$@"
    fi
}
