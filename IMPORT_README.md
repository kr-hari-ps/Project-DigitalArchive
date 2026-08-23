# Device-pair CSV importer

Imports the reviewed TABLET/PC device-pair CSV into the existing SQLite archive catalog.

**Read-only for source files.** It only writes to SQLite.

Usage:
```bash
~/my_scripts/digital_archive/import_device_pair_csv.sh \
  /path/to/build_device_pair_csv_TABLET_PC_YYYYMMDD_HHMMSS.csv \
  "$HOME/Master-Repository/.archive/catalog.db" TABLET PC
```

HKR/SKP exact-duplicate rule:
- only one copy has `/HKR/` or `/SKP/` -> select that copy
- both copies qualify -> select one deterministically (PC when available)
- neither qualifies -> leave REVIEW

The original CSV is unchanged.

Verify:
```bash
python3 ~/my_scripts/digital_archive/verify_catalog_import.py \
  "$HOME/Master-Repository/.archive/catalog.db"
```
