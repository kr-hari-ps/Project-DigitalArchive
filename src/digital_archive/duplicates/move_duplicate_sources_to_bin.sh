#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
BIN_ROOT="${2:-$HOME/Master-Repository/_Bin}"
MODE="${3:---dry-run}"

[[ -f "$DB" ]] || die "Database does not exist: $DB"

log_header "$DB"

echo "Mode         : DUPLICATE SOURCE CLEANUP"
echo "Bin root     : $BIN_ROOT"
echo "Requested    : $MODE"
echo "Only non-chosen exact duplicates are eligible."
echo

python3 "$SCRIPT_DIR/move_duplicate_sources_to_bin.py" \
    --db "$DB" \
    --bin-root "$BIN_ROOT" \
    "$MODE"

status=$?

if [[ $status -eq 0 ]]; then
    log_footer "SUCCESS"
else
    log_footer "FAILED"
fi

exit $status
