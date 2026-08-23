#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
MASTER_ROOT="${2:-$HOME/Master-Repository}"

shift 2 || true

[[ -f "$DB" ]] || die "Database does not exist: $DB"

log_header "$DB"
echo "Mode         : PHYSICAL COPY + SHA-256 VERIFICATION"
echo "Master root  : $MASTER_ROOT"
echo "Source files : NEVER modified"
echo

python3 "$SCRIPT_DIR/copy_planned_master.py" \
    --db "$DB" \
    --master-root "$MASTER_ROOT" \
    "$@"

log_footer "SUCCESS"
