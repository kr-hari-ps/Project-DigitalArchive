#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
mkdir -p "$(dirname "$DB")"
python3 "$SCRIPT_DIR/catalog_db.py" init "$DB"
echo "Catalog DB : $DB"
log_footer "SUCCESS"
