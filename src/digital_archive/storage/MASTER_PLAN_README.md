# Master Copy Planning

`plan_master_copy.py` creates `copy_manifest` rows with status `PLANNED`.

It does **not** copy, move, rename, or delete any file.

## Current first-pass destination rule

To preserve source folder structure without collisions, the planned destination is:

```text
MASTER_ROOT/
└── DEVICE_ID/
    └── original source-relative path
```

For example:

```text
TABLET/`epsilon/Personal/Finance/FY 2025-26/SKP/pnl-JJW692.xlsx
PC/ITR/FY-2025-26/SKP/demat_stmts/pnl-JJW692.xlsx
```

This is intentionally a temporary first-pass layout. Later organization can merge these into the preferred master structure while the database retains original source paths.

## Generate the plan

```bash
~/my_scripts/digital_archive/plan_master_copy.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository" \
  --source-root TABLET "$HOME/Migration-Work/Tablet-Original" \
  --source-root PC "$HOME/Documents"
```

## Important

The script only considers files selected by the catalog as master candidates:

- unique files
- chosen member of an exact duplicate group

Non-chosen duplicate members are not planned for copying.

Existing `COPIED`, `VERIFIED`, `FAILED`, and `SKIPPED` manifest rows are preserved. Only existing `PLANNED` rows are regenerated.

## Review before physical copy

Use Beekeeper Studio:

```sql
SELECT
    manifest_id,
    file_id,
    source_device_id,
    source_path,
    destination_path,
    source_size_bytes,
    source_sha256,
    status
FROM copy_manifest
WHERE status = 'PLANNED'
ORDER BY destination_path;
```

Expected current batch:

```text
292 PLANNED
```

The physical copy script should only be created after the planned manifest is reviewed.
