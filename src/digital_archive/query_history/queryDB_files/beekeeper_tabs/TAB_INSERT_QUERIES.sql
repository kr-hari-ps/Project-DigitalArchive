-- ============================================================
-- BEEKEEPER WORKSPACE TAB: INSERT OPERATIONS
-- Total Scripts in this Tab: 1
-- ============================================================

-- USER DESCRIPTION: Historical INSERT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-INS-049E8226-1 | NAME: history_insert_049E8226_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
INSERT INTO media_copy_manifest ( batch_id, inventory_id, source_device_id, source_path, destination_path, source_sha256, source_size_bytes, category, status, notes ) SELECT 'MEDIA_20260820_230000', inventory_id, source_device_id, source_path, '/home/harikr/Master-Repository/MEDIA_STAGING/' || source_device_id || '/' || relative_path, sha256, size_bytes, category, 'PLANNED', 'Initial multimedia staging copy; canonical media path not assigned.' FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND category <> 'DERIVED_CACHE' AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND keep_decision IS NULL ) );