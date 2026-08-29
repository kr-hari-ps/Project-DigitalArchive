#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"

[[ -f "$DB" ]] || die "Database does not exist: $DB"

log_header "$DB"
echo "Mode         : CANONICAL PLAN ONLY"
echo "Purpose      : Propose final logical document paths."
echo "No filesystem changes will be made."
echo

python3 "$SCRIPT_DIR/plan_canonical_paths.py" --db "$DB"

log_footer "SUCCESS"
