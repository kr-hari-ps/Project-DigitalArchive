#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB="${1:-$HOME/Master-Repository/.archive/catalog.db}"
python3 "$SCRIPT_DIR/init_catalog_v2.py" "$DB"
