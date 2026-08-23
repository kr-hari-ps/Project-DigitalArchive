# Multimedia Physical Copy

Copies only rows in `media_copy_manifest` with status `PLANNED`.

Default destination is already stored in the manifest under:

```text
Master-Repository/MEDIA_STAGING/TABLET/...
Master-Repository/MEDIA_STAGING/PC/...
```

The script:

- verifies source existence
- verifies source size
- verifies source SHA-256
- refuses different-content destination collisions
- uses `shutil.copy2`
- verifies destination size and SHA-256
- marks the row VERIFIED only after exact match
- leaves original source files untouched
- does not populate the main `files` table

Dry run:

```bash
./copy_media_manifest.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  MEDIA_20260820_230000 \
  --dry-run
```

Execute:

```bash
./copy_media_manifest.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  MEDIA_20260820_230000 \
  --execute
```

After success, expected:

```text
VERIFIED | 592
FAILED   | 0
```
