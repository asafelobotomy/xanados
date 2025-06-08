#!/usr/bin/env bash
set -euo pipefail


# Allow overriding the log directory via the LOG_DIR environment variable
LOG_DIR="${LOG_DIR:-/var/log/xanados}"

init_logging() {
    local prefix=${1:-script}


    # Attempt to create the preferred log directory. If that fails, fall back to
    # /tmp/xanados so logging still works even on read-only filesystems.
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "[WARN] Could not create log directory $LOG_DIR. Falling back to /tmp/xanados" >&2
        LOG_DIR=/tmp/xanados
        mkdir -p "$LOG_DIR" || {
            echo "[ERROR] Failed to create fallback log directory $LOG_DIR" >&2
            return 1
        }
    fi

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
