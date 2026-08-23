#!/usr/bin/env bash
set -u

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
STARTED="$(date '+%Y-%m-%d %H:%M:%S %Z')"
RUN_LOG="$LOG_DIR/${SCRIPT_NAME%.sh}_log_${TIMESTAMP}.txt"
GENERIC_LOG="$LOG_DIR/scripts_out_log.txt"

: > "$RUN_LOG"
: > "$GENERIC_LOG"

exec > >(tee "$RUN_LOG" "$GENERIC_LOG") 2>&1

log_header() {
    local source="${1:-}"
    echo "============================================================"
    echo "Script       : $SCRIPT_NAME"
    echo "Started      : $STARTED"
    echo "User         : ${USER:-unknown}"
    [[ -n "$source" ]] && echo "Source       : $source"
    echo "Run log      : $RUN_LOG"
    echo "Generic log  : $GENERIC_LOG"
    echo "============================================================"
}

log_footer() {
    local status="${1:-SUCCESS}"
    local completed
    completed="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo
    echo "============================================================"
    echo "Completed    : $completed"
    echo "Status       : $status"
    echo "Run log      : $RUN_LOG"
    echo "Generic log  : $GENERIC_LOG"
    echo "============================================================"
}

die() {
    echo "ERROR: $*" >&2
    log_footer "FAILED"
    exit 1
}
