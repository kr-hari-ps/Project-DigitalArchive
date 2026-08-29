# Multimedia Catalog Finalization v1

Catalogs the 585 already physically moved and SHA-256 verified multimedia records.

Input:
- multi_media_assets batch NONDOC_20260820_202341
- media_canonical_move_manifest batch MEDIA_CANONICAL_20260823, status APPLIED

Behavior:
- Preserves exact manual_category values in multi_media_assets.
- Reuses an existing IN_MASTER + MASTER files row when its SHA-256 matches.
- Prefers a matching existing canonical_path.
- Creates files rows only for genuinely new SHA/master identities.
- Adds file_sources if the exact file/device/source path is absent.
- Adds VERIFIED copy_manifest records if absent.
- Creates missing parent folders.
- Does NOT move/delete physical files.
- Does NOT modify existing MASTER canonical paths.

Dry run:
python3 finalize_media_catalog.py --db "$HOME/Master-Repository/.archive/catalog.db"

Execute after reviewing:
python3 finalize_media_catalog.py --db "$HOME/Master-Repository/.archive/catalog.db" --execute

Post-execution verification:
sql/MEDIA_CATALOG_FINALIZE_VERIFY.sql
