#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
MASTER_ROOT="${2:-$HOME/Master-Repository}"

shift 2 || true

[[ -f "$DB" ]] || die "Database does not exist: $DB"

log_header "$DB"

echo "Mode         : CANONICAL APPLY"
echo "Master root  : $MASTER_ROOT"
echo "Requested    : $*"
echo "Original Tablet/PC source trees are NOT touched."
echo

python3 "$SCRIPT_DIR/apply_canonical_paths.py" \
    --db "$DB" \
    --master-root "$MASTER_ROOT" \
    --apply-reviewed \
    "$@"

status=$?

if [[ $status -eq 0 ]]; then
    log_footer "SUCCESS"
else
    log_footer "FAILED"
fi

exit $status
