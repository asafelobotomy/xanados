#!/bin/bash
# xanadOS Package Manager Compatibility Layer
# Redirects pacman/yay calls to unified paru interface

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XPKG_CMD="$SCRIPT_DIR/xpkg.sh"

# Check if being called as pacman or yay
called_as="$(basename "$0")"

# Function to translate pacman arguments to paru
translate_pacman_args() {
    local args=("$@")
    local paru_args=()
    local operation=""
    local i=0

    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            "-S"|"--sync")
                operation="install"
                paru_args+=("-S")
                ;;
            "-Syu"|"-Syyu")
                operation="update"
                paru_args+=("-Syu")
                ;;
            "-Sy")
                operation="refresh"
                paru_args+=("-Sy")
                ;;
            "-R"|"--remove")
                operation="remove"
                paru_args+=("-R")
                ;;
            "-Rs")
                operation="remove"
                paru_args+=("-Rs")
                ;;
            "-Ss")
                operation="search"
                paru_args+=("-Ss")
                ;;
            "-Si")
                operation="info"
                paru_args+=("-Si")
                ;;
            "-Q"|"--query")
                operation="list"
                paru_args+=("-Q")
                ;;
            "-Sc")
                operation="clean"
                paru_args+=("-Sc")
                ;;
            "--needed")
                paru_args+=("--needed")
                ;;
            "--noconfirm")
                paru_args+=("--noconfirm")
                ;;
            *)
                # Pass through other arguments
                paru_args+=("${args[$i]}")
                ;;
        esac
        ((i++))
    done

    echo "${paru_args[@]}"
}

# Function to translate yay arguments to paru
translate_yay_args() {
    local args=("$@")
    local paru_args=()
    local i=0

    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            "-S"|"--sync")
                paru_args+=("-S")
                ;;
            "-Syu")
                paru_args+=("-Syu")
                ;;
            "-Sy")
                paru_args+=("-Sy")
                ;;
            "-R"|"--remove")
                paru_args+=("-R")
                ;;
            "-Rs")
                paru_args+=("-Rs")
                ;;
            "-Ss")
                paru_args+=("-Ss")
                ;;
            "-Si")
                paru_args+=("-Si")
                ;;
            "-Q"|"--query")
                paru_args+=("-Q")
                ;;
            "-Sc")
                paru_args+=("-Sc")
                ;;
            "--needed")
                paru_args+=("--needed")
                ;;
            "--noconfirm")
                paru_args+=("--noconfirm")
                ;;
            *)
                # Pass through other arguments
                paru_args+=("${args[$i]}")
                ;;
        esac
        ((i++))
    done

    echo "${paru_args[@]}"
}

# Main compatibility handler
main() {
    # Check if paru is available
    if ! command -v paru &>/dev/null; then
        echo "⚠️  paru not found. Installing..." >&2
        "$XPKG_CMD" >/dev/null 2>&1 || {
            echo "❌ Failed to install paru automatically" >&2
            exit 1
        }
    fi

    case "$called_as" in
        "pacman")
            echo "🔄 Redirecting pacman call to paru..." >&2
            if [[ $# -eq 0 ]]; then
                paru
            else
                local translated_args
                translated_args=$(translate_pacman_args "$@")
                # shellcheck disable=SC2086
                paru $translated_args
            fi
            ;;
        "yay")
            echo "🔄 Redirecting yay call to paru..." >&2
            if [[ $# -eq 0 ]]; then
                paru
            else
                local translated_args
                translated_args=$(translate_yay_args "$@")
                # shellcheck disable=SC2086
                paru $translated_args
            fi
            ;;
        *)
            # Direct paru call
            paru "$@"
            ;;
    esac
}

main "$@"
