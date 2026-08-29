#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
MASTER_ROOT="${2:-$HOME/Master-Repository}"

shift 2 || true

[[ -f "$DB" ]] || die "Database does not exist: $DB"

log_header "$DB"
echo "Mode         : PLAN ONLY"
echo "Purpose      : Generate PLANNED master copy manifest."
echo

python3 "$SCRIPT_DIR/plan_master_copy.py" \
    --db "$DB" \
    --master-root "$MASTER_ROOT" \
    "$@"

log_footer "SUCCESS"
