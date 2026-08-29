#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
BATCH_ID="${2:-}"
MODE="${3:---dry-run}"

[[ -f "$DB" ]] || die "Database does not exist: $DB"
[[ -n "$BATCH_ID" ]] || die "Canonical move batch ID is required."

log_header "$DB"

echo "Mode         : MEDIA CANONICAL MOVE"
echo "Batch        : $BATCH_ID"
echo "Requested    : $MODE"
echo "Original Tablet/PC source trees are NOT touched."
echo

python3 "$SCRIPT_DIR/move_media_canonical.py" \
    --db "$DB" \
    --batch-id "$BATCH_ID" \
    --master-root "$HOME/Master-Repository" \
    "$MODE"

status=$?

if [[ $status -eq 0 ]]; then
    log_footer "SUCCESS"
else
    log_footer "FAILED"
fi

exit $status
