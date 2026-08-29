# Canonical path and storage-state tracking

The catalog now distinguishes three things:

```text
source_path
    Where a source device originally had the file.

canonical_path
    Where the file belongs in the final logical repository.

master_path
    The current physical path used by the staging/active master.

storage_state
    Whether the current master copy is physically present here.
```

## Storage states

```text
IN_MASTER
    File is physically present in the active Master-Repository.

MOVED_EXTERNAL
    File was intentionally moved out of Master-Repository
    to another storage device.

IN_BIN
    File was moved to the archive/deletion bin.

MISSING
    Catalog says the file should exist but it was not found.
```

For `MOVED_EXTERNAL`, the catalog also records:

```text
external_device_id
external_path
moved_out_at
storage_move_reason
```

This lets the archive answer:

> "Where is this file now?"

even when the file is no longer physically in Master-Repository.

## Canonical path

`canonical_path` is the target logical organization.

Example:

```text
canonical_path:
Documents/Personal/Finance/ITR/FY 2025-26/SKP/demat_stmts/pnl-JJW692.xlsx
```

The physical path can temporarily be:

```text
Master-Repository/TABLET/`epsilon/Personal/Finance/FY 2025-26/SKP/pnl-JJW692.xlsx
```

Later we can reorganize the physical master to the canonical path without losing the original source path in `file_sources`.

## Migration

Run:

```bash
python3 ~/my_scripts/digital_archive/migrate_storage_fields.py \
  "$HOME/Master-Repository/.archive/catalog.db"
```

This migration is metadata-only and does not move files.
