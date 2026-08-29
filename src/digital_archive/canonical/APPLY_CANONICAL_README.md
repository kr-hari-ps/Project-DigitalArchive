# Apply Canonical Paths

Effective destination:

manual_canonical_path, when populated; otherwise proposed_canonical_path.

For REVIEW rows:
- manual path -> eligible
- proposed-only -> eligible for dry-run, but execute requires --confirm-proposed and interactive yes
- neither -> excluded

Dry run:
```bash
./apply_canonical_paths.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository" \
  --dry-run
```

Execute:
```bash
./apply_canonical_paths.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository" \
  --execute
```

To explicitly allow proposed-only rows:
```bash
./apply_canonical_paths.sh \
  "$HOME/Master-Repository/.archive/catalog.db" \
  "$HOME/Master-Repository" \
  --execute --confirm-proposed
```

The script then asks:
```text
Proceed with these proposed paths? [yes/no]:
```

Original Tablet and PC source trees are never touched.
All source files are size/hash verified before movement and destination hash verified after movement.
