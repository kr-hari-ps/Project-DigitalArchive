-- ============================================================
-- BEEKEEPER WORKSPACE TAB: DELETE OPERATIONS
-- Total Scripts in this Tab: 2
-- ============================================================

-- USER DESCRIPTION: Historical DELETE statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-DEL-A41BD992-1 | NAME: history_delete_A41BD992_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
DELETE FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical DELETE statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-DEL-D02419DC-1 | NAME: history_delete_D02419DC_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
DELETE FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_165411';