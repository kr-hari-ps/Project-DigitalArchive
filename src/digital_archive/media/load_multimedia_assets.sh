#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
DB="$HOME/Master-Repository/.archive/catalog.db"
log_header "$DB"
python3 "$SCRIPT_DIR/load_multimedia_assets.py" --db "$DB" "$@"
status=$?
if [[ $status -eq 0 ]]; then log_footer "SUCCESS"; else log_footer "FAILED"; fi
exit $status
