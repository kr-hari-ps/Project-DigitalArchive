# Duplicate Source Cleanup v2

This operation removes only redundant **source copies** that were already resolved as exact duplicates.

Eligible file:

```text
duplicate_groups.decision = KEEP_ONE
AND
file is not duplicate_groups.chosen_file_id
AND
source hash is verified
AND
chosen master copy is VERIFIED
```

The source copy is **moved to `_Bin`**, not permanently deleted.

## Bin layout

```text
Master-Repository/
└── _Bin/
    ├── TABLET_deleted/
    └── PC_deleted/
```

The script preserves the source filename. A numeric suffix is added if needed to avoid an overwrite.

## Dry run

```bash
./move_duplicate_sources_to_bin.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository/_Bin" \
  --dry-run
```

Expected current batch:

```text
Candidates : 18
```

All 18 should validate successfully before executing.

## Execute

```bash
./move_duplicate_sources_to_bin.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository/_Bin" \
  --execute
```

For every successful move:
- the file is verified in `_Bin`
- a `deletion_events` row is recorded
- `files.storage_state` becomes `IN_BIN`

No unique files are touched.

No different-content files are touched.

No canonical master files are touched.

## Important

The term "deleted" here means "removed from the original source location and placed in the archive bin." It is reversible as long as the bin is preserved.
