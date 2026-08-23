# Multimedia Asset Loader v2

Loads non-document files into `multi_media_assets` only.

Generated thumbnail/cache paths are automatically classified:
`category=DERIVED_CACHE`, `keep_decision=EXCLUDE`.

Recognized directory names:
- `.thumbnails`
- `thumbnails`
- `thumbs`
- narrow Android thumbnail/cache paths

These are staging exclusions only; no files are deleted.

Load:
```bash
./load_multimedia_assets.sh \
  --source-root TABLET "$HOME/Migration-Work/Tablet-Original" \
  --source-root PC "$HOME/Documents"
```

No physical copy/move/delete occurs.
