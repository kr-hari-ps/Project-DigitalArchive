# Physical Master Copy

This stage executes only rows with `copy_manifest.status = 'PLANNED'`.

## Safety

The script:
- never deletes source files
- never renames source files
- never moves source files
- verifies every source file before copying
- refuses to overwrite an existing destination containing different content
- verifies destination size and SHA-256 after copying
- marks a row `VERIFIED` only after the hash matches
- records failures in `copy_manifest`

If a source file is missing or its hash no longer matches the catalog, it is marked `FAILED` and not copied.

## Copy behavior

`shutil.copy2()` is used, preserving timestamps where supported.

Files keep the first-pass planned destination structure.

Example:

```text
Master-Repository/
├── TABLET/
└── PC/
```

The physical structure can be reorganized later.

## Metadata

On filesystems supporting Linux extended attributes, the script attempts to apply:

```text
user.archive.file_id
user.archive.device_map
user.archive.sha256
```

SQLite remains authoritative.

It also records folder rows in `folders` and file xattr results in `file_xattrs`.

## Run

```bash
~/my_scripts/digital_archive/copy_planned_master.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository"
```

Optional device-specific run:

```bash
~/my_scripts/digital_archive/copy_planned_master.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository" \
  --device TABLET
```

For the first full run, no device filter should be supplied.

## After the run

Review:

```sql
SELECT status, COUNT(*) AS file_count
FROM copy_manifest
GROUP BY status
ORDER BY status;
```

Expected after a fully successful first run:

```text
VERIFIED | 292
```

Then verify hashes:

```sql
SELECT COUNT(*) AS mismatches
FROM copy_manifest
WHERE status='VERIFIED'
  AND source_sha256 <> destination_sha256;
```

Expected:

```text
0
```
