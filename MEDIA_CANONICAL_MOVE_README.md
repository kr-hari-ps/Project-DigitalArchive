# Multimedia Canonical Move v1

Dry-run validates only PLANNED rows from `media_canonical_move_manifest`.

Dry run:
```bash
./move_media_canonical.sh   "$HOME/Master-Repository/.archive/catalog.db"   MEDIA_CANONICAL_20260823   --dry-run
```

The dry run verifies source existence, size, SHA-256, destination safety, destination collisions, and reports renames. It makes no changes.

Current expected state:
```text
PLANNED 585
RENAMES 40
COLLISIONS 0
```

The current package deliberately provides a validation-only canonical-move phase. Do not use `--execute` until the physical move implementation has been explicitly reviewed.
