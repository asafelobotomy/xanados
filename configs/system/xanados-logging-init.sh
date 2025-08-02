#!/bin/bash
# xanadOS Logging System Initialization
# Source this file to enable advanced logging in any script

# Load configuration if available
XANADOS_LOGGING_CONFIG="${XANADOS_ROOT:-/home/vm/Documents/xanadOS}/configs/system/xanados-logging.conf"
if [[ -f "$XANADOS_LOGGING_CONFIG" ]]; then
    source "$XANADOS_LOGGING_CONFIG"
fi

# Initialize logging for the calling script
if [[ -n "${BASH_SOURCE[1]}" ]]; then
    CALLING_SCRIPT="$(basename "${BASH_SOURCE[1]}")"
    auto_init_logging "$CALLING_SCRIPT" "${XANADOS_LOG_LEVEL:-INFO}" "${XANADOS_LOG_CATEGORY:-general}"
fi
