-- ============================================================
-- BEEKEEPER WORKSPACE TAB: SELECT OPERATIONS
-- Total Scripts in this Tab: 252
-- ============================================================

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1221BEEC-1 | NAME: history_select_1221BEEC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'NON_PERSONAL_REVIEW' and proposed_canonical_path not like '%cloud%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-58858D5F-1 | NAME: history_select_58858D5F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
select * from canonical_plan where proposed_canonical_path like '%Hari%' and plan_id=246;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-2E15168E-1 | NAME: history_select_2E15168E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
select * from sys_query_repo limit 10;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D510038C-1 | NAME: history_select_D510038C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: USE TEMP B-TREE FOR count(DISTINCT) | USE TEMP B-TREE FOR count(DISTINCT) | SCAN canonical_plan
SELECT COUNT(*) AS total_plans, COUNT(DISTINCT file_id) AS distinct_files, COUNT(DISTINCT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ) AS distinct_destinations FROM canonical_plan;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-371E8E60-1 | NAME: history_select_371E8E60_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM `canonical_plan` LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-E1939868-1 | NAME: history_select_E1939868_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%2024-25%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4AC4D63E-1 | NAME: history_select_4AC4D63E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN f | BLOOM FILTER ON de (file_id=?) | SEARCH de USING AUTOMATIC COVERING INDEX (file_id=?) LEFT-JOIN
SELECT COUNT(*) AS bin_without_event FROM files f LEFT JOIN deletion_events de ON de.file_id = f.file_id WHERE f.storage_state = 'IN_BIN' AND de.deletion_id IS NULL;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-85D97A7A-1 | NAME: history_select_85D97A7A_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH f USING COVERING INDEX idx_files_status (status=?) | SEARCH cp USING COVERING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) LEFT-JOIN ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS files_without_destination FROM files f LEFT JOIN canonical_plan cp ON cp.file_id = f.file_id WHERE f.status = 'MASTER' AND cp.file_id IS NULL;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-36A02006-1 | NAME: history_select_36A02006_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where manual_canonical_path like '%janaushadi%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-0D5FFDDC-1 | NAME: history_select_0D5FFDDC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, manual_canonical_path AS old_path, substr( manual_canonical_path, length('/home/harikr/Master-Repository/TABLET/') + 1 ) AS new_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/TABLET/%' ORDER BY plan_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-E38A7FB0-1 | NAME: history_select_E38A7FB0_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS remaining_prefixed_paths FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/TABLET/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-781A8D18-1 | NAME: history_select_781A8D18_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN f | BLOOM FILTER ON dm (file_id=?) | SEARCH dm USING AUTOMATIC COVERING INDEX (file_id=?) LEFT-JOIN | SEARCH dg USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) LEFT-JOIN | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT f.file_id, f.filename, f.extension, f.size_bytes, f.sha256, f.master_path, COALESCE(dg.duplicate_group_id, '') AS duplicate_group, COALESCE(dg.decision, 'UNIQUE') AS decision, CASE WHEN dg.chosen_file_id = f.file_id THEN 'KEEP' WHEN dg.duplicate_group_id IS NOT NULL THEN 'EXCLUDE_DUPLICATE' ELSE 'KEEP' END AS master_action FROM files f LEFT JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id ORDER BY master_action, f.filename;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-67DE1F72-1 | NAME: history_select_67DE1F72_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select proposed_canonical_path, count(*) as path_count from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-0DCECD03-1 | NAME: history_select_0DCECD03_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS manual_paths, SUM( CASE WHEN manual_canonical_path LIKE '/home/%' THEN 1 ELSE 0 END ) AS absolute_paths FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BE5C6992-1 | NAME: history_select_BE5C6992_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'QUICK_SHARE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-CA757F16-1 | NAME: history_select_CA757F16_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT proposal_rule, current_canonical_path, proposed_canonical_path, COUNT(*) AS file_count FROM canonical_plan WHERE proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY current_canonical_path, proposed_canonical_path ORDER BY current_canonical_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-423692C9-1 | NAME: history_select_423692C9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT COUNT(*) AS bin_without_event FROM files f LEFT JOIN deletion_events de ON de.file_id = f.file_id WHERE f.storage_state = 'IN_BIN' AND de.deletion_id IS NULL; SELECT de.file_id, de.device_id, de.bin_path, de.sha256 AS deletion_sha256, f.sha256 AS catalog_sha256 FROM deletion_events de JOIN files f ON f.file_id = de.file_id WHERE f.storage_state = 'IN_BIN' AND de.sha256 <> f.sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-B79FABD5-1 | NAME: history_select_B79FABD5_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN de | SEARCH f USING INTEGER PRIMARY KEY (rowid=?)
SELECT de.file_id, de.device_id, de.bin_path, de.sha256 AS deletion_sha256, f.sha256 AS catalog_sha256 FROM deletion_events de JOIN files f ON f.file_id = de.file_id WHERE f.storage_state = 'IN_BIN' AND de.sha256 <> f.sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-FAAA6A4E-1 | NAME: history_select_FAAA6A4E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT -- Quickly isolates 'Vehicle/' + the next folder name SUBSTR( proposed_canonical_path, 1, INSTR(SUBSTR(proposed_canonical_path, 9), '/') + 3 ) AS folder_path, COUNT(*) AS path_count FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' GROUP BY folder_path ORDER BY folder_path DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-925B6F8C-1 | NAME: history_select_925B6F8C_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_165411' AND duplicate_group IS NOT NULL ORDER BY duplicate_group, source_device_id, relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-C0D05E31-1 | NAME: history_select_C0D05E31_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT relative_path, filename FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND category = 'PHOTO' AND source_device_id = 'TABLET' AND ( relative_path LIKE '`epsilon/%' OR relative_path LIKE '%/`epsilon/%' ) AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND keep_decision IS NULL ) ) ORDER BY relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-26472633-1 | NAME: history_select_26472633_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS total_processed_rows, SUM(CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 1 ELSE 0 END) AS picture_count, SUM(CASE WHEN LOWER(source_path) LIKE '%movies%' THEN 1 ELSE 0 END) AS movie_count, SUM(CASE WHEN LOWER(source_path) LIKE '%music%' THEN 1 ELSE 0 END) AS music_count, SUM(CASE WHEN LOWER(source_path) NOT LIKE '%pictures%' AND LOWER(source_path) NOT LIKE '%movies%' AND LOWER(source_path) NOT LIKE '%music%' THEN 1 ELSE 0 END) AS uncategorized_count FROM multi_media_assets

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-07AC361B-1 | NAME: history_select_07AC361B_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT keep_decision, duplicate_reason, COUNT(*) AS file_count FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL GROUP BY keep_decision, duplicate_reason ORDER BY keep_decision, duplicate_reason;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C58F713A-1 | NAME: history_select_C58F713A_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%2022-23%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BA9B89D0-1 | NAME: history_select_BA9B89D0_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%VEHICLE%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BD5008A4-1 | NAME: history_select_BD5008A4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN dm USING COVERING INDEX sqlite_autoindex_duplicate_members_1 | SEARCH dg USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT dm.duplicate_group_id, COUNT(*) AS member_count, dg.chosen_file_id FROM duplicate_members dm JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id GROUP BY dm.duplicate_group_id, dg.chosen_file_id HAVING COUNT(*) > 2 ORDER BY dm.duplicate_group_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-97242761-1 | NAME: history_select_97242761_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%ACHAN%' and proposed_canonical_path not like '%SKP%' and proposed_canonical_path not like '%HKR%' and proposed_canonical_path not like '%RKN%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-DAB12EDA-1 | NAME: history_select_DAB12EDA_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE DocumentMappings | SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SEARCH mma USING AUTOMATIC PARTIAL COVERING INDEX (batch_id=? AND source_device_id=? AND category=?) | USE TEMP B-TREE FOR DISTINCT | SCAN DocumentMappings | USE TEMP B-TREE FOR GROUP BY ⚡ [Optimized: Fast index lookup active]
WITH ImageFiles AS ( SELECT substr( mma.relative_path, 1, length(mma.relative_path) - length(mma.filename) - 1 ) AS image_source_folder FROM multi_media_assets mma WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' AND ( mma.keep_decision = 'KEEP' OR ( mma.duplicate_status = 'UNIQUE' AND mma.keep_decision IS NULL ) ) ), DocumentMappings AS ( SELECT DISTINCT i.image_source_folder, substr( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ), 1, length( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) ) - length(f.filename) - 1 ) AS canonical_folder FROM ImageFiles i JOIN file_sources fs ON substr( fs.source_path, 1, length(fs.source_path) - length(fs.source_path) + length(fs.source_path) - length(f.filename) - 1 ) IS NOT NULL JOIN files f ON f.file_id = fs.file_id JOIN canonical_plan cp ON cp.file_id = f.file_id WHERE substr( fs.source_path, 1, length(fs.source_path) - length(f.filename) - 1 ) = '/home/harikr/Migration-Work/Tablet-Original/' || i.image_source_folder ) SELECT image_source_folder, canonical_folder, COUNT(*) AS matching_document_rows FROM DocumentMappings GROUP BY image_source_folder, canonical_folder ORDER BY image_source_folder, canonical_folder;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3E7C3F07-1 | NAME: history_select_3E7C3F07_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select proposed_canonical_path, count(*) as path_count from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' group by proposed_canonical_path order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-487BB059-1 | NAME: history_select_487BB059_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT * FROM `files` LIMIT 5 OFFSET 0; SELECT group_concat(name, ', ') AS column_names FROM pragma_table_info('files'); SELECT storage_state, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes FROM files GROUP BY storage_state ORDER BY storage_state; SELECT COUNT(*) AS files, COUNT(canonical_path) AS with_canonical_path FROM files; SELECT proposal_rule, COUNT(*) AS file_count FROM canonical_plan GROUP BY proposal_rule ORDER BY file_count DESC; SELECT proposal_rule, substr(current_canonical_path, 1, instr(current_canonical_path || '/', '/') - 1) AS current_root, COUNT(*) AS file_count FROM canonical_plan WHERE proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY proposal_rule, current_root ORDER BY file_count DESC; SELECT proposal_rule, current_canonical_path, proposed_canonical_path, COUNT(*) AS file_count FROM canonical_plan WHERE proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY current_canonical_path, proposed_canonical_path ORDER BY current_canonical_path; SELECT cp.plan_id, cp.file_id, fs.device_id, fs.source_path, f.filename, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' ORDER BY fs.source_path; SELECT fs.device_id, CASE WHEN instr(fs.source_path, '/') > 0 THEN substr(fs.source_path, 1, instr(fs.source_path, '/') - 1) ELSE fs.source_path END AS source_root, COUNT(*) AS file_count FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY fs.device_id, source_root ORDER BY file_count DESC, fs.device_id, source_root; SELECT fs.device_id, CASE WHEN instr(fs.source_path, '/') > 0 THEN substr( fs.source_path, 1, instr( substr(fs.source_path, instr(fs.source_path, '/') + 1), '/' ) + instr(fs.source_path, '/') ) ELSE fs.source_path END AS source_folder_pattern, COUNT(*) AS file_count FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY fs.device_id, source_folder_pattern ORDER BY file_count DESC, fs.device_id; SELECT fs.device_id, CASE WHEN instr(fs.source_path, '/') > 0 THEN substr( fs.source_path, 1, instr( substr(fs.source_path, instr(fs.source_path, '/') + 1), '/' ) + instr(fs.source_path, '/') ) ELSE fs.source_path END AS source_folder_pattern, COUNT(*) AS file_count FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY fs.device_id, source_folder_pattern ORDER BY file_count DESC, fs.device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F6551285-1 | NAME: history_select_F6551285_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
SELECT count(*) FROM `sys_query_repo`

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-6887DDA1-1 | NAME: history_select_6887DDA1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work%' and current_canonical_path like '%pc%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-AD81F9A3-1 | NAME: history_select_AD81F9A3_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM `canonical_plan` where proposed_canonical_path like '%to-review%' LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-B09E4A80-1 | NAME: history_select_B09E4A80_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%' ORDER BY plan_id LIMIT 30;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-FB2472D3-1 | NAME: history_select_FB2472D3_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT a.duplicate_group, a.sha256, a.size_bytes, a.category, -- File A Details a.source_device_id AS file_a_device, a.filename AS file_a_name, a.relative_path AS file_a_path, -- File B Details b.source_device_id AS file_b_device, b.filename AS file_b_name, b.relative_path AS file_b_path FROM multi_media_assets a INNER JOIN multi_media_assets b ON a.duplicate_group = b.duplicate_group -- Prevents matching a file to itself and filters out duplicate mirrored pairs AND (a.source_device_id < b.source_device_id OR (a.source_device_id = b.source_device_id AND a.relative_path < b.relative_path)) WHERE a.duplicate_group IS NOT NULL order by a.duplicate_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-40098777-1 | NAME: history_select_40098777_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' and proposed_canonical_path not like '%SKP%' and proposed_canonical_path not like '%HKR%' and proposed_canonical_path not like '%RKN%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-ECE5E572-1 | NAME: history_select_ECE5E572_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'NON_PERSONAL_REVIEW' order by proposal_rule desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-CF9F17CD-1 | NAME: history_select_CF9F17CD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%' ORDER BY plan_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-50356899-1 | NAME: history_select_50356899_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH fs USING INDEX idx_sources_device (device_id=?) | SEARCH dm USING COVERING INDEX sqlite_autoindex_duplicate_members_1 (duplicate_group_id=? AND file_id=?) ⚡ [Optimized: Fast index lookup active]
SELECT * FROM duplicate_members dm JOIN file_sources fs ON fs.file_id = dm.file_id WHERE dm.duplicate_group_id = 'DUP-0011' AND fs.device_id = 'TABLET' LIMIT 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-EDF1C39B-1 | NAME: history_select_EDF1C39B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS absolute_canonical_paths FROM canonical_plan WHERE COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) LIKE '/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-5A66833F-1 | NAME: history_select_5A66833F_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT CASE WHEN source_path LIKE '%pictures%' THEN 'Pictures' WHEN source_path LIKE '%movies%' THEN 'Movies' WHEN source_path LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END AS extracted_category, COUNT(*) AS asset_count FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117' GROUP BY CASE WHEN source_path LIKE '%pictures%' THEN 'Pictures' WHEN source_path LIKE '%movies%' THEN 'Movies' WHEN source_path LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END ORDER BY asset_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3B801195-1 | NAME: history_select_3B801195_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT * FROM `files` LIMIT 5 OFFSET 0; SELECT group_concat(name, ', ') AS column_names FROM pragma_table_info('files'); SELECT storage_state, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes FROM files GROUP BY storage_state ORDER BY storage_state; SELECT COUNT(*) AS files, COUNT(canonical_path) AS with_canonical_path FROM files;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-7B00B0C8-1 | NAME: history_select_7B00B0C8_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN media_copy_manifest | USE TEMP B-TREE FOR GROUP BY
SELECT status, COUNT(*) AS file_count FROM media_copy_manifest WHERE batch_id='MEDIA_20260820_230000' GROUP BY status ORDER BY status;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-59664DC2-1 | NAME: history_select_59664DC2_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='ARCHIVE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F8482C4D-1 | NAME: history_select_F8482C4D_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'preserve_tablet_personal_structure';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-17808425-1 | NAME: history_select_17808425_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups USING INDEX sqlite_autoindex_duplicate_groups_1 ⚡ [Optimized: Fast index lookup active]
SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups ORDER BY duplicate_group_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-ACB97A6C-1 | NAME: history_select_ACB97A6C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, proposed_canonical_path AS old_path, replace(proposed_canonical_path, '`epsilon/', '') AS new_path FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%`epsilon%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D84C8835-1 | NAME: history_select_D84C8835_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN files
SELECT * FROM `files` LIMIT 5 OFFSET 0;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8388C0CC-1 | NAME: history_select_8388C0CC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
SELECT count(*) FROM `sys_query_repo` WHERE query_type = 'UPDATE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-83BB5B41-1 | NAME: history_select_83BB5B41_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups USING COVERING INDEX sqlite_autoindex_duplicate_groups_1 ⚡ [Optimized: Fast index lookup active]
select count(*) from duplicate_groups;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5FBF4B61-1 | NAME: history_select_5FBF4B61_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN pragma_table_info VIRTUAL TABLE INDEX 0:
SELECT group_concat(name, ', ') AS column_names FROM pragma_table_info('files');

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5EBEE7B0-1 | NAME: history_select_5EBEE7B0_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS remaining_prefixed_paths FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-63FFD092-1 | NAME: history_select_63FFD092_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: USE TEMP B-TREE FOR count(DISTINCT) | USE TEMP B-TREE FOR count(DISTINCT) | SCAN media_copy_manifest
SELECT COUNT(*) AS manifest_rows, COUNT(DISTINCT inventory_id) AS distinct_inventory, COUNT(DISTINCT destination_path) AS distinct_destinations FROM media_copy_manifest WHERE batch_id = 'MEDIA_20260820_230000';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-FD3E1E45-1 | NAME: history_select_FD3E1E45_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SEARCH multi_media_assets USING INTEGER PRIMARY KEY (rowid=?) | LIST SUBQUERY 4 | MATERIALIZE RankedAssets | CO-ROUTINE (subquery-5) | SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY | SCAN (subquery-5) | SCAN RankedAssets | CORRELATED SCALAR SUBQUERY 2 | SCAN RankedAssets | CORRELATED SCALAR SUBQUERY 3 | SCAN RankedAssets
WITH RankedAssets AS ( SELECT inventory_id, duplicate_group, CASE WHEN LOWER(filename) LIKE '%(%' THEN 1 ELSE 0 END AS parenthetical_name, ROW_NUMBER() OVER ( PARTITION BY duplicate_group ORDER BY CASE WHEN LOWER(filename) LIKE '%(%' THEN 1 ELSE 0 END, source_modified_at DESC, inventory_id DESC ) AS rank_within_group FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL ) UPDATE multi_media_assets SET keep_decision = ( SELECT CASE WHEN rank_within_group = 1 THEN 'KEEP' ELSE 'EXCLUDE' END FROM RankedAssets WHERE RankedAssets.inventory_id = multi_media_assets.inventory_id ), duplicate_reason = ( SELECT CASE WHEN rank_within_group = 1 AND parenthetical_name = 0 THEN 'PREFERRED_NAME_AND_NEWEST' WHEN rank_within_group = 1 AND parenthetical_name = 1 THEN 'NEWEST_AVAILABLE' WHEN parenthetical_name = 1 THEN 'PARENTHETICAL_DUPLICATE' ELSE 'OLDER_DUPLICATE' END FROM RankedAssets WHERE RankedAssets.inventory_id = multi_media_assets.inventory_id ) WHERE inventory_id IN ( SELECT inventory_id FROM RankedAssets );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4AC7FD27-1 | NAME: history_select_4AC7FD27_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN dm | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH dg USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) LEFT-JOIN | SEARCH cp USING COVERING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) LEFT-JOIN ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS selected_files_without_plan FROM files f JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id LEFT JOIN canonical_plan cp ON cp.file_id = f.file_id WHERE ( dg.duplicate_group_id IS NULL OR dg.chosen_file_id = f.file_id ) AND cp.file_id IS NULL;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-57457E31-1 | NAME: history_select_57457E31_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 'pic_thumb' WHEN LOWER(source_path) LIKE '%movies%' THEN 'movie_thumb' WHEN LOWER(source_path) LIKE '%music%' THEN 'music_thumb' END AS extracted_category, COUNT(*) AS total_records FROM multi_media_assets WHERE category = 'DERIVED_CACHE' GROUP BY CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 'pic_thumb' WHEN LOWER(source_path) LIKE '%movies%' THEN 'movie_thumb' WHEN LOWER(source_path) LIKE '%music%' THEN 'music_thumb' END ORDER BY total_records DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-281A9536-1 | NAME: history_select_281A9536_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='OTHER';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C28B6C3B-1 | NAME: history_select_C28B6C3B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH copy_manifest USING INDEX idx_manifest_status (status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS mismatches FROM copy_manifest WHERE status='VERIFIED' AND source_sha256 <> destination_sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-74F65BC6-1 | NAME: history_select_74F65BC6_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN media_metadata
select * from media_metadata where camera_make is not null;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BAFD59A7-1 | NAME: history_select_BAFD59A7_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-56F524B7-1 | NAME: history_select_56F524B7_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT CASE WHEN source_path LIKE '%/pictures/%' THEN 'Pictures' WHEN source_path LIKE '%/movies/%' THEN 'Movies' WHEN source_path LIKE '%/music/%' THEN 'Music' ELSE 'Unknown/Other' END AS extracted_category, COUNT(*) AS asset_count FROM multi_media_assets -- WHERE batch_id = 'NONDOC_20260820_175117' GROUP BY CASE WHEN source_path LIKE '%/pictures/%' THEN 'Pictures' WHEN source_path LIKE '%/movies/%' THEN 'Movies' WHEN source_path LIKE '%/music/%' THEN 'Music' ELSE 'Unknown/Other' END ORDER BY asset_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8E5EF6E2-1 | NAME: history_select_8E5EF6E2_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN cp | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH fs USING COVERING INDEX sqlite_autoindex_file_sources_1 (file_id=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT cp.plan_id, cp.file_id, fs.device_id, fs.source_path, f.filename, cp.current_canonical_path, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' ORDER BY fs.source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-714D52D9-1 | NAME: history_select_714D52D9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BA7B94D4-1 | NAME: history_select_BA7B94D4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'DOWNLOAD_TO_REVIEW';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-DD94C6E5-1 | NAME: history_select_DD94C6E5_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY 2023-24%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BED6F396-1 | NAME: history_select_BED6F396_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select count(*) as to_review_manual from canonical_plan where proposed_canonical_path like '%to-review%' and manual_canonical_path is not null ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5EE634B6-1 | NAME: history_select_5EE634B6_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS missing_effective_paths FROM canonical_plan WHERE NULLIF( TRIM( COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ), '' ) IS NULL;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-FE1A983C-1 | NAME: history_select_FE1A983C_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * from multi_media_assets limit 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-ABA7AF92-1 | NAME: history_select_ABA7AF92_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN folders USING INDEX sqlite_autoindex_folders_1 ⚡ [Optimized: Fast index lookup active]
SELECT folder_id, master_path, folder_type, device_summary FROM folders ORDER BY master_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-00CFB03D-1 | NAME: history_select_00CFB03D_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%financial%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-63461F03-1 | NAME: history_select_63461F03_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY 2025-26%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8A23A895-1 | NAME: history_select_8A23A895_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%Hari%' and plan_id != 246;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-7028770B-1 | NAME: history_select_7028770B_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT duplicate_group, inventory_id, source_device_id, source_path, relative_path, filename, sha256, source_modified_at FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IN ( 'NONDOC-DUP-0008', 'NONDOC-DUP-0015' ) ORDER BY duplicate_group, inventory_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-EF4D6792-1 | NAME: history_select_EF4D6792_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select count(*) as epsilon_present from canonical_plan where proposed_canonical_path like '%VEHICLE%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-E78DE3BE-1 | NAME: history_select_E78DE3BE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'CONSERVATIVE_REVIEW';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-90AA383B-1 | NAME: history_select_90AA383B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: USE TEMP B-TREE FOR count(DISTINCT) | SEARCH canonical_plan USING INDEX idx_canonical_plan_status (review_status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS applied_files, COUNT(DISTINCT file_id) AS distinct_files FROM canonical_plan WHERE review_status = 'APPLIED';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-4593B108-1 | NAME: history_select_4593B108_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT duplicate_group, COUNT(*) AS member_count, GROUP_CONCAT( source_device_id || '|' || relative_path, CHAR(10) ) AS members FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_165411' AND duplicate_group IS NOT NULL GROUP BY duplicate_group ORDER BY duplicate_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-B7143D39-1 | NAME: history_select_B7143D39_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule like 'preserve_tablet_personal%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-840508C1-1 | NAME: history_select_840508C1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
select proposal_rule, count(*) as proposal_rule_count from canonical_plan group by proposal_rule order by proposal_rule_count;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4D743411-1 | NAME: history_select_4D743411_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INDEX idx_canonical_plan_status (review_status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS review_rows, SUM( CASE WHEN proposed_canonical_path IS NOT NULL AND TRIM(proposed_canonical_path) <> '' THEN 1 ELSE 0 END ) AS with_proposed_path FROM canonical_plan WHERE review_status = 'REVIEW';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-482C2F6C-1 | NAME: history_select_482C2F6C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT fs.source_path, cp.proposed_canonical_path, cp.proposal_rule FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE fs.source_path LIKE '%EAadhaar%' ORDER BY fs.source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-A76A14B8-1 | NAME: history_select_A76A14B8_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
WITH RankedAssets AS ( SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision, created_at, -- Ranks files within the same duplicate group. Oldest gets 1, newer files get 2, 3, etc. ROW_NUMBER() OVER ( PARTITION BY duplicate_group ORDER BY created_at ASC, inventory_id ASC ) AS rank_within_group FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117' AND duplicate_group IS NOT NULL ) SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision, created_at, -- Labeling the file status based on the rank CASE WHEN rank_within_group = 1 THEN 'Original (Oldest)' ELSE 'Duplicate (Newer File)' END AS file_age_status FROM RankedAssets ORDER BY duplicate_group, rank_within_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-09AF93F3-1 | NAME: history_select_09AF93F3_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PERSONAL_JOB';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9642C05B-1 | NAME: history_select_9642C05B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups WHERE duplicate_group_id = 'DUP-0011'; SELECT decision, COUNT(*) AS groups FROM duplicate_groups GROUP BY decision;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-DBF7753F-1 | NAME: history_select_DBF7753F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work/%' and current_canonical_path like '%pc%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-0F697518-1 | NAME: history_select_0F697518_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, datetime(source_modified_at, 'unixepoch', 'localtime') AS modified_at, sha256, keep_decision, duplicate_reason FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND keep_decision = 'KEEP' ORDER BY category, relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D5A73FB4-1 | NAME: history_select_D5A73FB4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH fs USING INDEX idx_sources_device (device_id=?) | SEARCH dm USING COVERING INDEX sqlite_autoindex_duplicate_members_1 (duplicate_group_id=? AND file_id=?) ⚡ [Optimized: Fast index lookup active]
SELECT dm.file_id FROM duplicate_members dm JOIN file_sources fs ON fs.file_id = dm.file_id WHERE dm.duplicate_group_id = 'DUP-0011' AND fs.device_id = 'TABLET' LIMIT 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-182C4C39-1 | NAME: history_select_182C4C39_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS remaining FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_165411';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-972FFDE7-1 | NAME: history_select_972FFDE7_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * FROM `multi_media_assets` LIMIT 100 OFFSET 0;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-F9A54FC4-1 | NAME: history_select_F9A54FC4_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT duplicate_group, COUNT(*) AS members, GROUP_CONCAT( filename || ' | ' || source_device_id || ' | ' || datetime(source_modified_at, 'unixepoch', 'localtime'), CHAR(10) ) AS candidates FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL GROUP BY duplicate_group ORDER BY duplicate_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-59526A3A-1 | NAME: history_select_59526A3A_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT proposal_rule, substr(current_canonical_path, 1, instr(current_canonical_path || '/', '/') - 1) AS current_root, COUNT(*) AS file_count FROM canonical_plan WHERE proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY proposal_rule, current_root ORDER BY file_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-CD966146-1 | NAME: history_select_CD966146_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups ORDER BY duplicate_group_id; SELECT decision, COUNT(*) AS groups FROM duplicate_groups GROUP BY decision; SELECT * FROM duplicate_members dm JOIN file_sources fs ON fs.file_id = dm.file_id WHERE dm.duplicate_group_id = 'DUP-0011' AND fs.device_id = 'TABLET' LIMIT 1; SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups WHERE duplicate_group_id = 'DUP-0011'; SELECT decision, COUNT(*) AS groups FROM duplicate_groups GROUP BY decision; -- ============================================================ -- File Migration Review -- Source / provenance / duplicate decision view -- READ-ONLY -- ============================================================ SELECT f.file_id, f.filename, f.extension, f.size_bytes, f.sha256, fs.device_id, fs.source_path, dg.duplicate_group_id, dg.decision AS duplicate_decision, dg.chosen_file_id, CASE WHEN dg.chosen_file_id = f.file_id THEN 'CHOSEN' WHEN dg.duplicate_group_id IS NOT NULL THEN 'DUPLICATE' ELSE 'UNIQUE' END AS file_decision, dg.notes FROM files f LEFT JOIN file_sources fs ON fs.file_id = f.file_id LEFT JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id ORDER BY COALESCE(dg.duplicate_group_id, ''), f.filename, fs.device_id; SELECT COUNT(*) AS file_records FROM files; SELECT COUNT(*) AS source_records FROM file_sources;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3EB1CA5F-1 | NAME: history_select_3EB1CA5F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select count(*) from canonical_plan where proposed_canonical_path like '%to-review%' and manual_canonical_path is not null ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8B904692-1 | NAME: history_select_8B904692_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY_2022-23%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-7A567765-1 | NAME: history_select_7A567765_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%Hari%' ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-55132568-1 | NAME: history_select_55132568_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE (subquery-1) | SCAN files | USE TEMP B-TREE FOR GROUP BY | SCAN (subquery-1)
SELECT COUNT(*) AS collisions FROM ( SELECT canonical_path FROM files WHERE storage_state='IN_MASTER' GROUP BY canonical_path HAVING COUNT(*) > 1 );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5EA6C455-1 | NAME: history_select_5EA6C455_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM `canonical_plan` where proposed_canonical_path like '%`epsilon%' LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-ACA594F9-1 | NAME: history_select_ACA594F9_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS candidate_files, SUM(size_bytes) AS candidate_bytes FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND category <> 'DERIVED_CACHE' ) );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F773AF0E-1 | NAME: history_select_F773AF0E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path LIKE '%FY_20%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-19DC0293-1 | NAME: history_select_19DC0293_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN cp | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH fs USING COVERING INDEX sqlite_autoindex_file_sources_1 (file_id=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT cp.plan_id, cp.file_id, fs.device_id, fs.source_path, f.filename, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' ORDER BY fs.source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-828FA846-1 | NAME: history_select_828FA846_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM `canonical_plan` where proposed_canonical_path like '%personal%' LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5FA7B1F2-1 | NAME: history_select_5FA7B1F2_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
SELECT proposed_canonical_path FROM canonical_plan WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-57CEE033-1 | NAME: history_select_57CEE033_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
WITH RECURSIVE SeparatedPaths AS ( -- Base Step: Grab all paths and find their total length SELECT proposed_canonical_path AS original_path, proposed_canonical_path AS current_truncation, LENGTH(proposed_canonical_path) AS current_len FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' UNION ALL -- Recursive Step: Chop 1 character off the end if it's not a slash SELECT original_path, SUBSTR(current_truncation, 1, current_len - 1), current_len - 1 FROM SeparatedPaths WHERE SUBSTR(current_truncation, current_len, 1) != '/' AND current_len > 0 ) -- Outer Query: Group and count using the clean folder paths SELECT current_truncation AS folder_path, COUNT(*) AS path_count FROM SeparatedPaths -- This filter ensures we only select the rows where the loop successfully stopped at the last slash WHERE SUBSTR(current_truncation, LENGTH(current_truncation), 1) = '/' OR current_truncation = '' GROUP BY folder_path ORDER BY folder_path DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1EDF51B1-1 | NAME: history_select_1EDF51B1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select count(*) from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' and proposed_canonical_path like '%2025-26%' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-417D1FD3-1 | NAME: history_select_417D1FD3_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * FROM multi_media_assets where source_device_id ='TABLET' AND category ='DERIVED_CACHE' AND LOWER(source_path) NOT LIKE '%pictures%' AND LOWER(source_path) NOT LIKE '%movies%' AND LOWER(source_path) NOT LIKE '%music%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-579FB918-1 | NAME: history_select_579FB918_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%2023-24%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-C1605EAF-1 | NAME: history_select_C1605EAF_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='VIDEO';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-21415D67-1 | NAME: history_select_21415D67_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY_20%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-8E41A473-1 | NAME: history_select_8E41A473_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * FROM `multi_media_assets` LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-9F46DCDF-1 | NAME: history_select_9F46DCDF_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * FROM multi_media_assets where source_device_id ='TABLET' AND category ='DERIVED_CACHE' --AND LOWER(source_path) NOT LIKE '%pictures%' --AND LOWER(source_path) NOT LIKE '%movies%' --AND LOWER(source_path) NOT LIKE '%music%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8A4CC324-1 | NAME: history_select_8A4CC324_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1E163AC5-1 | NAME: history_select_1E163AC5_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT distinct plan_id, proposed_canonical_path AS old_path, replace(proposed_canonical_path, '`epsilon/', '') AS new_path FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%`epsilon%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-790F1DFE-1 | NAME: history_select_790F1DFE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INDEX idx_canonical_plan_status (review_status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS missing_effective_paths FROM canonical_plan WHERE review_status = 'REVIEW' AND ( COALESCE( NULLIF(TRIM(manual_canonical_path), ''), NULLIF(TRIM(proposed_canonical_path), '') ) IS NULL );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-01D6B2FB-1 | NAME: history_select_01D6B2FB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT -- Total size of all tracking records combined SUM(f.size_bytes) AS current_total_bytes, -- Pretty formatted total current space (GB) ROUND(SUM(f.size_bytes) / 1024.0 / 1024.0 / 1024.0, 2) AS current_total_gb, -- Total space that will be safely kept (Unique files + Chosen winners) SUM(CASE WHEN dg.duplicate_group_id IS NULL OR dg.chosen_file_id = f.file_id THEN f.size_bytes ELSE 0 END) AS projected_retained_bytes, -- Pretty formatted kept space (GB) ROUND(SUM(CASE WHEN dg.duplicate_group_id IS NULL OR dg.chosen_file_id = f.file_id THEN f.size_bytes ELSE 0 END) / 1024.0 / 1024.0 / 1024.0, 2) AS projected_retained_gb, -- Total wasted space to be cleared (Redundant matching entries) SUM(CASE WHEN dg.duplicate_group_id IS NOT NULL AND COALESCE(dg.chosen_file_id, '') != f.file_id THEN f.size_bytes ELSE 0 END) AS reclaimable_bytes, -- Pretty formatted wasted space (GB) - Your actual disk savings ROUND(SUM(CASE WHEN dg.duplicate_group_id IS NOT NULL AND COALESCE(dg.chosen_file_id, '') != f.file_id THEN f.size_bytes ELSE 0 END) / 1024.0 / 1024.0 / 1024.0, 2) AS reclaimable_gb, -- Percentage of storage savings relative to total archive pool ROUND( (SUM(CASE WHEN dg.duplicate_group_id IS NOT NULL AND COALESCE(dg.chosen_file_id, '') != f.file_id THEN f.size_bytes ELSE 0 END) * 100.0) / NULLIF(SUM(f.size_bytes), 0), 2 ) AS storage_savings_percent FROM files f LEFT JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-32309FFC-1 | NAME: history_select_32309FFC_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS epsilon_photos FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND category = 'PHOTO' AND source_device_id = 'TABLET' AND ( relative_path LIKE '`epsilon/%' OR relative_path LIKE '%/`epsilon/%' ) AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND keep_decision IS NULL ) );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-675195AB-1 | NAME: history_select_675195AB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY
SELECT CASE WHEN manual_canonical_path LIKE '/home/harikr/Master-Repository/TABLET/%' THEN 'TABLET_PREFIX' WHEN manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%' THEN 'PC_PREFIX' ELSE 'OTHER' END AS path_type, COUNT(*) AS file_count FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' GROUP BY path_type ORDER BY path_type;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-F7AAB016-1 | NAME: history_select_F7AAB016_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE SourceFolders | SCAN 7 CONSTANT ROWS | SCAN mma | SCAN sf | USE TEMP B-TREE FOR ORDER BY
WITH SourceFolders(folder_path) AS ( VALUES ('`epsilon'), ('`epsilon/Personal/Hospital/folder1'), ('`epsilon/Personal/Identity_n_Accounts'), ('`epsilon/Personal/Vehicle/kwid/amaron_battery_06_2026'), ('`epsilon/Work/Jobs'), ('`epsilon/media_data/Profile_pics'), ('`epsilon/media_data/Walls') ) SELECT mma.inventory_id, mma.relative_path, mma.filename, sf.folder_path FROM multi_media_assets mma JOIN SourceFolders sf ON mma.relative_path LIKE sf.folder_path || '/%' WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' ORDER BY sf.folder_path, mma.relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C5477942-1 | NAME: history_select_C5477942_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN file_sources USING COVERING INDEX idx_sources_device ⚡ [Optimized: Fast index lookup active]
SELECT device_id, COUNT(*) AS source_files FROM file_sources GROUP BY device_id ORDER BY device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-82E7C072-1 | NAME: history_select_82E7C072_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN files | USE TEMP B-TREE FOR GROUP BY
SELECT storage_state, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes FROM files GROUP BY storage_state ORDER BY storage_state;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-A2291C85-1 | NAME: history_select_A2291C85_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT a.duplicate_group, a.sha256, a.size_bytes, a.category, -- File A Details a.source_device_id AS file_a_device, a.filename AS file_a_name, a.relative_path AS file_a_path, -- File B Details b.source_device_id AS file_b_device, b.filename AS file_b_name, b.relative_path AS file_b_path FROM multi_media_assets a INNER JOIN multi_media_assets b ON a.duplicate_group = b.duplicate_group -- Prevents matching a file to itself and filters out duplicate mirrored pairs AND (a.source_device_id < b.source_device_id OR (a.source_device_id = b.source_device_id AND a.relative_path < b.relative_path)) WHERE a.duplicate_group IS NOT NULL order by a.sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-FCE200FA-1 | NAME: history_select_FCE200FA_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
WITH RankedAssets AS ( SELECT source_device_id, relative_path, filename, category, size_bytes, sha256, duplicate_group, -- Change the ORDER BY clause to prefer specific files (e.g., oldest, newest) ROW_NUMBER() OVER(PARTITION BY sha256 ORDER BY source_device_id) AS row_num FROM multi_media_assets WHERE sha256 IS NOT NULL ) SELECT source_device_id, relative_path, filename, category, size_bytes, sha256, duplicate_group FROM RankedAssets -- To see all duplicate files (excluding the first one), change to: WHERE row_num > 1 WHERE row_num = 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-2023E33C-1 | NAME: history_select_2023E33C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
SELECT * FROM `sys_query_repo` LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-1550EBB9-1 | NAME: history_select_1550EBB9_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117' AND duplicate_group IS NOT NULL ORDER BY duplicate_group, source_device_id, relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BDB7BF90-1 | NAME: history_select_BDB7BF90_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM canonical_plan LIMIT 10 OFFSET 10;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D3A75EBB-1 | NAME: history_select_D3A75EBB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY_2025-26%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-44EAB8E2-1 | NAME: history_select_44EAB8E2_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%HariPAN%' ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-CFCB9D7D-1 | NAME: history_select_CFCB9D7D_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'NON_PERSONAL_REVIEW' and proposed_canonical_path like '%google%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A094B61A-1 | NAME: history_select_A094B61A_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN c | SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
WITH pf_id AS ( SELECT plan_id, file_id FROM canonical_plan WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%') SELECT * FROM canonical_plan c CROSS JOIN pf_id p WHERE c.plan_id = p.plan_id AND c.file_id = p.file_id

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-68478A98-1 | NAME: history_select_68478A98_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT a.duplicate_group, a.sha256, a.size_bytes, a.category, -- File A Details a.source_device_id AS file_a_device, a.filename AS file_a_name, a.relative_path AS file_a_path, -- File B Details b.source_device_id AS file_b_device, b.filename AS file_b_name, b.relative_path AS file_b_path FROM multi_media_assets a INNER JOIN multi_media_assets b ON a.duplicate_group = b.duplicate_group -- Prevents matching a file to itself and filters out duplicate mirrored pairs AND (a.source_device_id < b.source_device_id OR (a.source_device_id = b.source_device_id AND a.relative_path < b.relative_path)) WHERE a.duplicate_group IS NOT NULL;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-7351A655-1 | NAME: history_select_7351A655_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%Hari%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-784B5C5C-1 | NAME: history_select_784B5C5C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work%' and current_canonical_path like '%pc';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-0B323516-1 | NAME: history_select_0B323516_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS total_processed_rows, SUM(CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 1 ELSE 0 END) AS picture_count, SUM(CASE WHEN LOWER(source_path) LIKE '%movies%' THEN 1 ELSE 0 END) AS movie_count, SUM(CASE WHEN LOWER(source_path) LIKE '%music%' THEN 1 ELSE 0 END) AS music_count, SUM(CASE WHEN LOWER(source_path) NOT LIKE '%pictures%' AND LOWER(source_path) NOT LIKE '%movies%' AND LOWER(source_path) NOT LIKE '%music%' THEN 1 ELSE 0 END) AS uncategorized_count FROM multi_media_assets WHERE category = 'DERIVED_CACHE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-22E1ECB4-1 | NAME: history_select_22E1ECB4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
select * from canonical_plan where proposal_rule = 'PERSONAL_DOCS' and plan_id in (80, 109);

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-356D3090-1 | NAME: history_select_356D3090_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
select proposal_rule, count(*) as proposal_rule_count from canonical_plan group by proposal_rule order by proposal_rule_count desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-0BFE2379-1 | NAME: history_select_0BFE2379_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work/%' and current_canonical_path like '%pc%' and proposed_canonical_path like '%Hari%' and proposed_canonical_path like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3BF0C1EA-1 | NAME: history_select_3BF0C1EA_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH fs USING COVERING INDEX sqlite_autoindex_file_sources_1 (file_id=?) ⚡ [Optimized: Fast index lookup active]
SELECT cp.plan_id, cp.file_id, f.filename, f.size_bytes, f.sha256, fs.device_id, fs.source_path, cp.manual_canonical_path, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.file_id IN (53, 65) ORDER BY cp.file_id, fs.device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1CAE9A05-1 | NAME: history_select_1CAE9A05_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(CASE WHEN proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' THEN 1 END) AS count_rule_a, COUNT(CASE WHEN proposed_canonical_path LIKE '%`epsilon%' THEN 1 END) AS count_path_b, COUNT(CASE WHEN proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%`epsilon%' THEN 1 END) AS count_both_combined FROM canonical_plan;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-4E084B3A-1 | NAME: history_select_4E084B3A_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT duplicate_group, sha256, source_device_id, relative_path, filename, category, size_bytes FROM multi_media_assets -- Directly isolates rows that belong to a duplicate group WHERE duplicate_group IS NOT NULL ORDER BY duplicate_group, source_device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-0CB9B18C-1 | NAME: history_select_0CB9B18C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN file_sources USING COVERING INDEX idx_sources_device ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS source_records FROM file_sources;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-C01C848A-1 | NAME: history_select_C01C848A_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE ImageFolders | SCAN mma | USE TEMP B-TREE FOR DISTINCT | SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SCAN img | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR count(DISTINCT) | USE TEMP B-TREE FOR group_concat(DISTINCT) ⚡ [Optimized: Fast index lookup active]
WITH ImageFolders AS ( SELECT DISTINCT substr( mma.relative_path, 1, length(mma.relative_path) - length(mma.filename) - 1 ) AS source_folder FROM multi_media_assets mma WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' ) SELECT img.source_folder, COUNT(DISTINCT cp.file_id) AS matching_document_files, GROUP_CONCAT( DISTINCT COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) ) AS matching_document_canonical_paths FROM ImageFolders img JOIN file_sources fs ON fs.source_path LIKE '/home/harikr/Migration-Work/Tablet-Original/' || img.source_folder || '/%' JOIN canonical_plan cp ON cp.file_id = fs.file_id GROUP BY img.source_folder ORDER BY img.source_folder;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-F9521678-1 | NAME: history_select_F9521678_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='DERIVED_CACHE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-B07BD659-1 | NAME: history_select_B07BD659_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
WITH RankedAssets AS ( SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision, created_at, -- Ranks files within the same duplicate group. Oldest gets 1, newer files get 2, 3, etc. ROW_NUMBER() OVER ( PARTITION BY duplicate_group ORDER BY created_at ASC, inventory_id ASC ) AS rank_within_group FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117' AND duplicate_group IS NOT NULL AND filename not like '% (%' ) SELECT inventory_id, duplicate_group, source_device_id, relative_path, filename, category, size_bytes, sha256, keep_decision, created_at, -- Labeling the file status based on the rank CASE WHEN rank_within_group = 1 THEN 'Original (Oldest)' ELSE 'Duplicate (Newer File)' END AS file_age_status FROM RankedAssets ORDER BY duplicate_group, rank_within_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-50EDA2DD-1 | NAME: history_select_50EDA2DD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work/%' and current_canonical_path like '%pc%' and proposed_canonical_path not like '%Hari%' and proposed_canonical_path not like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9DA0E6BE-1 | NAME: history_select_9DA0E6BE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%VEHICLE%' AND proposed_canonical_path like '%KWID%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-766955A8-1 | NAME: history_select_766955A8_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select * from canonical_plan where proposal_rule = 'NON_PERSONAL_REVIEW' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-3DEB0ACA-1 | NAME: history_select_3DEB0ACA_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select count(*) from multi_media_assets;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C2CC0516-1 | NAME: history_select_C2CC0516_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%2025-26%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C7ABE109-1 | NAME: history_select_C7ABE109_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT -- Quickly isolates 'Vehicle/' + the next folder name SUBSTR( proposed_canonical_path, 1, INSTR(SUBSTR(proposed_canonical_path, 9), '/') + 7 ) AS folder_path, COUNT(*) AS path_count FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' GROUP BY folder_path ORDER BY folder_path DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-3F7D1308-1 | NAME: history_select_3F7D1308_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE RankedAssets | CO-ROUTINE (subquery-3) | SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY | SCAN (subquery-3) | SCAN RankedAssets | USE TEMP B-TREE FOR ORDER BY
WITH RankedAssets AS ( SELECT inventory_id, duplicate_group, filename, source_modified_at, source_device_id, relative_path, CASE WHEN LOWER(filename) LIKE '%(%' THEN 1 ELSE 0 END AS parenthetical_name, ROW_NUMBER() OVER ( PARTITION BY duplicate_group ORDER BY CASE WHEN LOWER(filename) LIKE '%(%' THEN 1 ELSE 0 END, source_modified_at DESC, inventory_id DESC ) AS rank_within_group FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL ) SELECT duplicate_group, inventory_id, source_device_id, relative_path, filename, datetime( source_modified_at, 'unixepoch', 'localtime' ) AS modified_at, CASE WHEN rank_within_group = 1 THEN 'KEEP' ELSE 'EXCLUDE' END AS proposed_decision, CASE WHEN rank_within_group = 1 AND parenthetical_name = 0 THEN 'PREFERRED_NAME_AND_NEWEST' WHEN rank_within_group = 1 AND parenthetical_name = 1 THEN 'NEWEST_AVAILABLE' WHEN parenthetical_name = 1 THEN 'PARENTHETICAL_DUPLICATE' ELSE 'OLDER_DUPLICATE' END AS decision_reason FROM RankedAssets ORDER BY duplicate_group, rank_within_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C079BBDF-1 | NAME: history_select_C079BBDF_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_status ⚡ [Optimized: Fast index lookup active]
SELECT review_status, COUNT(*) AS file_count FROM canonical_plan GROUP BY review_status ORDER BY review_status;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-B92B883E-1 | NAME: history_select_B92B883E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS epsilon_paths FROM canonical_plan WHERE proposed_canonical_path LIKE 'Documents/`epsilon/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-6CB48A32-1 | NAME: history_select_6CB48A32_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select count(*) from canonical_plan where proposed_canonical_path like '%to-review%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-163F83A8-1 | NAME: history_select_163F83A8_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%fin%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4DCFC6DE-1 | NAME: history_select_4DCFC6DE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups | USE TEMP B-TREE FOR GROUP BY
SELECT decision, COUNT(*) AS duplicate_groups FROM duplicate_groups GROUP BY decision ORDER BY decision;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-1F138DF9-1 | NAME: history_select_1F138DF9_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT category, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND category <> 'DERIVED_CACHE' ) ) GROUP BY category ORDER BY file_count DESC, category;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9A44D141-1 | NAME: history_select_9A44D141_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM canonical_plan WHERE proposed_canonical_path LIKE '%epsilon%' LIMIT 100

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BE253FCE-1 | NAME: history_select_BE253FCE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PERSONAL_DOCS';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-64623BF2-1 | NAME: history_select_64623BF2_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(*) AS total_processed_rows, SUM(CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 1 ELSE 0 END) AS picture_count, SUM(CASE WHEN LOWER(source_path) LIKE '%movies%' THEN 1 ELSE 0 END) AS movie_count, SUM(CASE WHEN LOWER(source_path) LIKE '%music%' THEN 1 ELSE 0 END) AS music_count, SUM(CASE WHEN LOWER(source_path) NOT LIKE '%pictures%' AND LOWER(source_path) NOT LIKE '%movies%' AND LOWER(source_path) NOT LIKE '%music%' THEN 1 ELSE 0 END) AS uncategorized_count FROM multi_media_assets WHERE category = 'DERIVED_CACHE' -- from multi_media_assets where source_device_id ='TABLET' and category ='DERIVED_CACHE' ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-683A1FD7-1 | NAME: history_select_683A1FD7_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
select source_device_id, count(*) from multi_media_assets group by source_device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-15D8F4EF-1 | NAME: history_select_15D8F4EF_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select count(*) as to_review_present from canonical_plan where proposed_canonical_path like '%to-review%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9E066D7E-1 | NAME: history_select_9E066D7E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
SELECT proposed_canonical_path AS old_path, REPLACE(proposed_canonical_path, 'Vehicle/', 'Vehicle/wego/') AS new_path FROM canonical_plan WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-6485BBDC-1 | NAME: history_select_6485BBDC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-E38F8587-1 | NAME: history_select_E38F8587_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%' ORDER BY plan_id; SELECT CASE WHEN manual_canonical_path LIKE '/home/harikr/Master-Repository/TABLET/%' THEN 'TABLET_PREFIX' WHEN manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%' THEN 'PC_PREFIX' ELSE 'OTHER' END AS path_type, COUNT(*) AS file_count FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' GROUP BY path_type ORDER BY path_type; SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%' ORDER BY plan_id LIMIT 30; SELECT plan_id, manual_canonical_path AS old_path, substr( manual_canonical_path, length('/home/harikr/Master-Repository/PC/') + 1 ) AS new_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%' ORDER BY plan_id; -- Normalize manual canonical paths: -- remove only the physical TABLET staging prefix. -- Does not touch source_path, master_path, hashes, or files. UPDATE canonical_plan SET manual_canonical_path = substr( manual_canonical_path, length('/home/harikr/Master-Repository/PC/') + 1 ), updated_at = CURRENT_TIMESTAMP WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%'; SELECT COUNT(*) AS remaining_prefixed_paths FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/%'; SELECT COUNT(*) AS manual_paths, SUM( CASE WHEN manual_canonical_path LIKE '/home/%' THEN 1 ELSE 0 END ) AS absolute_paths FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> ''; SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' AND manual_canonical_path NOT LIKE 'Documents/%' ORDER BY plan_id; SELECT cp.plan_id, cp.file_id, f.filename, COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) AS effective_canonical_path, cp.review_status FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id ORDER BY effective_canonical_path; SELECT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) AS effective_canonical_path, COUNT(*) AS file_count, GROUP_CONCAT(file_id, ', ') AS file_ids FROM canonical_plan GROUP BY effective_canonical_path HAVING COUNT(*) > 1 ORDER BY file_count DESC, effective_canonical_path; SELECT COUNT(*) AS missing_effective_paths FROM canonical_plan WHERE NULLIF( TRIM( COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ), '' ) IS NULL; SELECT COUNT(*) AS total_plans, COUNT(DISTINCT file_id) AS distinct_files, COUNT(DISTINCT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ) AS distinct_destinations FROM canonical_plan; SELECT cp.plan_id, cp.file_id, f.filename, f.size_bytes, f.sha256, fs.device_id, fs.source_path, cp.manual_canonical_path, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.file_id IN (53, 65) ORDER BY cp.file_id, fs.device_id; SELECT review_status, COUNT(*) AS file_count FROM canonical_plan GROUP BY review_status ORDER BY review_status; SELECT COUNT(*) AS applied_files, COUNT(DISTINCT file_id) AS distinct_files FROM canonical_plan WHERE review_status = 'APPLIED'; SELECT COUNT(*) AS canonical_collisions FROM ( SELECT canonical_path FROM files WHERE storage_state='IN_MASTER' GROUP BY canonical_path HAVING COUNT(*) > 1 ); SELECT COUNT(*) AS applied_hash_mismatches FROM copy_manifest WHERE verification_method='SHA256_AFTER_CANONICAL_MOVE' AND status='VERIFIED' AND source_sha256 <> destination_sha256; SELECT COUNT(*) AS review_rows, SUM( CASE WHEN proposed_canonical_path IS NOT NULL AND TRIM(proposed_canonical_path) <> '' THEN 1 ELSE 0 END ) AS with_proposed_path FROM canonical_plan WHERE review_status = 'REVIEW'; SELECT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) AS effective_canonical_path, COUNT(*) AS file_count, GROUP_CONCAT(file_id, ', ') AS file_ids FROM canonical_plan GROUP BY effective_canonical_path HAVING COUNT(*) > 1 ORDER BY file_count DESC, effective_canonical_path; SELECT COUNT(*) AS review_rows, SUM( CASE WHEN manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' THEN 1 ELSE 0 END ) AS with_manual_path FROM canonical_plan WHERE review_status = 'REVIEW'; SELECT COUNT(*) AS missing_effective_paths FROM canonical_plan WHERE review_status = 'REVIEW' AND ( COALESCE( NULLIF(TRIM(manual_canonical_path), ''), NULLIF(TRIM(proposed_canonical_path), '') ) IS NULL ); SELECT COUNT(*) AS total_plans, COUNT(DISTINCT file_id) AS distinct_files, COUNT( DISTINCT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ) AS distinct_destinations FROM canonical_plan; SELECT COUNT(*) AS selected_files_without_plan FROM files f JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id LEFT JOIN canonical_plan cp ON cp.file_id = f.file_id WHERE ( dg.duplicate_group_id IS NULL OR dg.chosen_file_id = f.file_id ) AND cp.file_id IS NULL; SELECT COUNT(*) AS absolute_canonical_paths FROM canonical_plan WHERE COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) LIKE '/%'; SELECT storage_state, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes FROM files GROUP BY storage_state ORDER BY storage_state; WITH ImageFolders AS ( SELECT DISTINCT substr( mma.relative_path, 1, length(mma.relative_path) - length(mma.filename) - 1 ) AS source_folder FROM multi_media_assets mma WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' ) SELECT img.source_folder, COUNT(DISTINCT cp.file_id) AS matching_document_files, GROUP_CONCAT( DISTINCT COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) ) AS matching_document_canonical_paths FROM ImageFolders img JOIN file_sources fs ON fs.source_path LIKE '/home/harikr/Migration-Work/Tablet-Original/' || img.source_folder || '/%' JOIN canonical_plan cp ON cp.file_id = fs.file_id GROUP BY img.source_folder ORDER BY img.source_folder;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A48F8725-1 | NAME: history_select_A48F8725_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select * from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3EB1CA5F-2 | NAME: history_select_3EB1CA5F_2 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select count(*) from canonical_plan where proposed_canonical_path like '%to-review%' and manual_canonical_path is not null ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-38541B44-1 | NAME: history_select_38541B44_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
select source_device_id, category, count(*) from multi_media_assets group by source_device_id, category;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-6ADF1B40-1 | NAME: history_select_6ADF1B40_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY 2024-25%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-D93B6F95-1 | NAME: history_select_D93B6F95_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT COUNT(CASE WHEN source_path LIKE '%/pictures/%' THEN 1 END) AS picture_count, COUNT(CASE WHEN source_path LIKE '%/movies/%' THEN 1 END) AS movie_count, COUNT(CASE WHEN source_path LIKE '%/music/%' THEN 1 END) AS music_count, COUNT(CASE WHEN source_path NOT LIKE '%/pictures/%' AND source_path NOT LIKE '%/movies/%' AND source_path NOT LIKE '%/music/%' THEN 1 END) AS other_count FROM multi_media_assets;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-30B58708-1 | NAME: history_select_30B58708_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select * from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' and proposed_canonical_path like '%SKP%' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-81FF44E9-1 | NAME: history_select_81FF44E9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN media_copy_manifest
SELECT COUNT(*) AS hash_mismatches FROM media_copy_manifest WHERE batch_id = 'MEDIA_20260820_230000' AND status = 'VERIFIED' AND source_sha256 <> destination_sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-6E7491B4-1 | NAME: history_select_6E7491B4_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT substr( relative_path, 1, length(relative_path) - length(filename) - 1 ) AS folder_path, COUNT(*) AS file_count FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND source_device_id = 'TABLET' AND category = 'PHOTO' AND relative_path LIKE '`epsilon/%' GROUP BY folder_path ORDER BY folder_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3E1CC4CF-1 | NAME: history_select_3E1CC4CF_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select count(*) as epsilon_present from canonical_plan where proposed_canonical_path like '%epsilon%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-CCDBBB9E-1 | NAME: history_select_CCDBBB9E_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 'Pictures' WHEN LOWER(source_path) LIKE '%movies%' THEN 'Movies' WHEN LOWER(source_path) LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END AS extracted_category, COUNT(*) AS asset_count FROM multi_media_assets GROUP BY CASE WHEN LOWER(source_path) LIKE '%pictures%' THEN 'Pictures' WHEN LOWER(source_path) LIKE '%movies%' THEN 'Movies' WHEN LOWER(source_path) LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END ORDER BY asset_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-6963F718-1 | NAME: history_select_6963F718_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN pragma_table_info VIRTUAL TABLE INDEX 0:
SELECT group_concat(name, ', ') AS column_names FROM pragma_table_info('canonical_plan');

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4B8B3EC6-1 | NAME: history_select_4B8B3EC6_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
select * from canonical_plan where manual_canonical_path is not null; select count(*) from canonical_plan where proposed_canonical_path like '%to-review%'; select count(*) from canonical_plan where proposed_canonical_path like '%to-review%' and manual_canonical_path is not null ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-12A90443-1 | NAME: history_select_12A90443_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT duplicate_group, COUNT(*) AS member_count, GROUP_CONCAT( source_device_id || '|' || relative_path, CHAR(10) ) AS members FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_175117' AND duplicate_group IS NOT NULL GROUP BY duplicate_group ORDER BY duplicate_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-0E3F169F-1 | NAME: history_select_0E3F169F_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT source_path, COUNT(*) as failed_matches_count FROM multi_media_assets WHERE LOWER(source_path) NOT LIKE '%pictures%' AND LOWER(source_path) NOT LIKE '%movies%' AND LOWER(source_path) NOT LIKE '%music%' GROUP BY source_path ORDER BY failed_matches_count DESC LIMIT 10;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8BFD19F0-1 | NAME: history_select_8BFD19F0_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
SELECT count(*) FROM `sys_query_repo` WHERE query_type = 'SELECT';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4228EACB-1 | NAME: history_select_4228EACB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE (subquery-1) | SCAN files | USE TEMP B-TREE FOR GROUP BY | SCAN (subquery-1)
SELECT COUNT(*) AS canonical_collisions FROM ( SELECT canonical_path FROM files WHERE storage_state='IN_MASTER' GROUP BY canonical_path HAVING COUNT(*) > 1 );

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-A2430990-1 | NAME: history_select_A2430990_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN pragma_table_info VIRTUAL TABLE INDEX 0: | USE TEMP B-TREE FOR ORDER BY
SELECT name FROM pragma_table_info('multi_media_assets') WHERE name IN ( 'source_created_at', 'source_modified_at', 'source_accessed_at', 'source_ctime_at', 'duplicate_reason' ) ORDER BY name;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D1E1BC15-1 | NAME: history_select_D1E1BC15_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN copy_manifest USING COVERING INDEX idx_manifest_status ⚡ [Optimized: Fast index lookup active]
SELECT status, COUNT(*) AS file_count FROM copy_manifest GROUP BY status ORDER BY status;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-063FC8EC-1 | NAME: history_select_063FC8EC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A50DB264-1 | NAME: history_select_A50DB264_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: USE TEMP B-TREE FOR count(DISTINCT) | USE TEMP B-TREE FOR count(DISTINCT) | SCAN canonical_plan
SELECT COUNT(*) AS total_plans, COUNT(DISTINCT file_id) AS distinct_files, COUNT( DISTINCT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) ) AS distinct_destinations FROM canonical_plan;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-17808425-2 | NAME: history_select_17808425_2 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups USING INDEX sqlite_autoindex_duplicate_groups_1 ⚡ [Optimized: Fast index lookup active]
SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups ORDER BY duplicate_group_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1B20264D-1 | NAME: history_select_1B20264D_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN f | SEARCH fs USING COVERING INDEX sqlite_autoindex_file_sources_1 (file_id=?) LEFT-JOIN | BLOOM FILTER ON dm (file_id=?) | SEARCH dm USING AUTOMATIC COVERING INDEX (file_id=?) LEFT-JOIN | SEARCH dg USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) LEFT-JOIN | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT f.file_id, f.filename, f.extension, f.size_bytes, f.sha256, fs.device_id, fs.source_path, dg.duplicate_group_id, dg.decision AS duplicate_decision, dg.chosen_file_id, CASE WHEN dg.chosen_file_id = f.file_id THEN 'CHOSEN' WHEN dg.duplicate_group_id IS NOT NULL THEN 'DUPLICATE' ELSE 'UNIQUE' END AS file_decision, dg.notes FROM files f LEFT JOIN file_sources fs ON fs.file_id = f.file_id LEFT JOIN duplicate_members dm ON dm.file_id = f.file_id LEFT JOIN duplicate_groups dg ON dg.duplicate_group_id = dm.duplicate_group_id ORDER BY COALESCE(dg.duplicate_group_id, ''), f.filename, fs.device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-E00C53C1-1 | NAME: history_select_E00C53C1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT proposal_rule, COUNT(*) AS file_count FROM canonical_plan GROUP BY proposal_rule ORDER BY file_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-E8D1BC14-1 | NAME: history_select_E8D1BC14_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING INDEX idx_sources_device | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT fs.device_id, CASE WHEN instr(fs.source_path, '/') > 0 THEN substr( fs.source_path, 1, instr( substr(fs.source_path, instr(fs.source_path, '/') + 1), '/' ) + instr(fs.source_path, '/') ) ELSE fs.source_path END AS source_folder_pattern, COUNT(*) AS file_count FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY fs.device_id, source_folder_pattern ORDER BY file_count DESC, fs.device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-633CE765-1 | NAME: history_select_633CE765_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'preserve_tablet_personal%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-0F33F8CD-1 | NAME: history_select_0F33F8CD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: You can only execute one statement at a time.)
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE'; select count(*) as epsilon_present from canonical_plan where proposed_canonical_path like '%epsilon%'; select count(*) as to_review_manual from canonical_plan where proposed_canonical_path like '%to-review%' and manual_canonical_path is not null ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-3E0C582C-1 | NAME: history_select_3E0C582C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY_2023-24%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-8BC214CD-1 | NAME: history_select_8BC214CD_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE SourceFolders | SCAN 7 CONSTANT ROWS | SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SCAN sf | SEARCH mma USING AUTOMATIC PARTIAL COVERING INDEX (batch_id=? AND source_device_id=? AND category=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
WITH SourceFolders(folder_path) AS ( VALUES ('`epsilon'), ('`epsilon/Personal/Hospital/folder1'), ('`epsilon/Personal/Identity_n_Accounts'), ('`epsilon/Personal/Vehicle/kwid/amaron_battery_06_2026'), ('`epsilon/Work/Jobs'), ('`epsilon/media_data/Profile_pics'), ('`epsilon/media_data/Walls') ), MediaFiles AS ( SELECT mma.inventory_id, mma.relative_path, mma.filename, sf.folder_path AS source_folder FROM multi_media_assets mma JOIN SourceFolders sf ON mma.relative_path LIKE sf.folder_path || '/%' WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' AND ( mma.keep_decision = 'KEEP' OR ( mma.duplicate_status = 'UNIQUE' AND mma.keep_decision IS NULL ) ) ) SELECT mf.inventory_id, mf.relative_path AS image_source_path, mf.filename AS image_filename, mf.source_folder, COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) AS document_effective_canonical_path, substr( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ), 1, length( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) ) - length(f.filename) - 1 ) AS document_canonical_folder FROM MediaFiles mf JOIN file_sources fs ON fs.source_path LIKE '/home/harikr/Migration-Work/Tablet-Original/' || mf.source_folder || '/%' JOIN files f ON f.file_id = fs.file_id JOIN canonical_plan cp ON cp.file_id = f.file_id ORDER BY mf.source_folder, mf.relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-0D541171-1 | NAME: history_select_0D541171_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='DERIVED_CACHE' and source_path not like '%pictures%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A62D1D95-1 | NAME: history_select_A62D1D95_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT * FROM `canonical_plan` where proposed_canonical_path like '%epsilon%' LIMIT 100 OFFSET 0

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-626E32F9-1 | NAME: history_select_626E32F9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN cp | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | USE TEMP B-TREE FOR ORDER BY
SELECT cp.plan_id, cp.file_id, f.filename, COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) AS effective_canonical_path, cp.review_status FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id ORDER BY effective_canonical_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D1E1BC15-2 | NAME: history_select_D1E1BC15_2 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN copy_manifest USING COVERING INDEX idx_manifest_status ⚡ [Optimized: Fast index lookup active]
SELECT status, COUNT(*) AS file_count FROM copy_manifest GROUP BY status ORDER BY status;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8645EB22-1 | NAME: history_select_8645EB22_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING INDEX idx_sources_device | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT fs.device_id, CASE WHEN instr(fs.source_path, '/') > 0 THEN substr(fs.source_path, 1, instr(fs.source_path, '/') - 1) ELSE fs.source_path END AS source_root, COUNT(*) AS file_count FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW' GROUP BY fs.device_id, source_root ORDER BY file_count DESC, fs.device_id, source_root;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-7D236CE3-1 | NAME: history_select_7D236CE3_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH dg USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) | SEARCH dm USING COVERING INDEX sqlite_autoindex_duplicate_members_1 (duplicate_group_id=?) | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH fs USING COVERING INDEX sqlite_autoindex_file_sources_1 (file_id=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT f.file_id, f.filename, fs.device_id, fs.source_path, f.size_bytes, f.sha256, CASE WHEN dg.chosen_file_id = f.file_id THEN 'KEEP' ELSE 'EXCLUDE_DUPLICATE' END AS master_action FROM duplicate_groups dg JOIN duplicate_members dm ON dm.duplicate_group_id = dg.duplicate_group_id JOIN files f ON f.file_id = dm.file_id JOIN file_sources fs ON fs.file_id = f.file_id WHERE dg.duplicate_group_id = 'DUP-0008' ORDER BY master_action DESC, fs.device_id, fs.source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-16BA4A29-1 | NAME: history_select_16BA4A29_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT duplicate_group, sha256, category, size_bytes, COUNT(*) AS total_files, -- Merges all device IDs and file names into a single text block STRING_AGG(source_device_id, ', ') AS devices, STRING_AGG(filename, ' | ') AS file_names, STRING_AGG(relative_path, ' | ') AS relative_paths FROM multi_media_assets WHERE duplicate_group IS NOT NULL GROUP BY duplicate_group, sha256, category, size_bytes ORDER BY total_files DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-50356899-2 | NAME: history_select_50356899_2 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH fs USING INDEX idx_sources_device (device_id=?) | SEARCH dm USING COVERING INDEX sqlite_autoindex_duplicate_members_1 (duplicate_group_id=? AND file_id=?) ⚡ [Optimized: Fast index lookup active]
SELECT * FROM duplicate_members dm JOIN file_sources fs ON fs.file_id = dm.file_id WHERE dm.duplicate_group_id = 'DUP-0011' AND fs.device_id = 'TABLET' LIMIT 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-F6384C58-1 | NAME: history_select_F6384C58_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR count(DISTINCT)
SELECT duplicate_group, COUNT(DISTINCT sha256) AS distinct_hashes FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL GROUP BY duplicate_group HAVING COUNT(DISTINCT sha256) > 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-96A61A4E-1 | NAME: history_select_96A61A4E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: USE TEMP B-TREE FOR count(DISTINCT) | USE TEMP B-TREE FOR count(DISTINCT) | SEARCH copy_manifest USING INDEX idx_manifest_status (status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS manifest_rows, COUNT(DISTINCT file_id) AS distinct_files, COUNT(DISTINCT destination_path) AS distinct_destinations FROM copy_manifest WHERE status = 'PLANNED';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1BE272D9-1 | NAME: history_select_1BE272D9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'NON_PERSONAL_REVIEW';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9FED2A49-1 | NAME: history_select_9FED2A49_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, file_id, manual_canonical_path FROM canonical_plan WHERE manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' AND manual_canonical_path NOT LIKE 'Documents/%' ORDER BY plan_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-0749B876-1 | NAME: history_select_0749B876_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT source_device_id, COUNT(*) AS photo_files, SUM(size_bytes) AS total_bytes FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND category = 'PHOTO' AND ( keep_decision = 'KEEP' OR ( duplicate_status = 'UNIQUE' AND keep_decision IS NULL ) ) GROUP BY source_device_id ORDER BY source_device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-ACD225D4-1 | NAME: history_select_ACD225D4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN media_copy_manifest | USE TEMP B-TREE FOR GROUP BY
SELECT destination_path, COUNT(*) AS file_count FROM media_copy_manifest WHERE batch_id = 'MEDIA_20260820_230000' GROUP BY destination_path HAVING COUNT(*) > 1;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-8987C6BC-1 | NAME: history_select_8987C6BC_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR DISTINCT
SELECT DISTINCT relative_path FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND category = 'PHOTO' AND source_device_id = 'TABLET' ORDER BY relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-DB2C089C-1 | NAME: history_select_DB2C089C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select count(*) from canonical_plan where manual_canonical_path is not null;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8A830614-1 | NAME: history_select_8A830614_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-909A5C6D-1 | NAME: history_select_909A5C6D_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path, category from multi_media_assets where source_device_id ='TABLET' and category ='DERIVED_CACHE' ;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-2AD2A768-1 | NAME: history_select_2AD2A768_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH copy_manifest USING INDEX idx_manifest_status (status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS applied_hash_mismatches FROM copy_manifest WHERE verification_method='SHA256_AFTER_CANONICAL_MOVE' AND status='VERIFIED' AND source_sha256 <> destination_sha256;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-3C29A487-1 | NAME: history_select_3C29A487_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT * FROM multi_media_assets where source_device_id ='TABLET' --AND category ='DERIVED_CACHE' --AND LOWER(source_path) NOT LIKE '%pictures%' --AND LOWER(source_path) NOT LIKE '%movies%' --AND LOWER(source_path) NOT LIKE '%music%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-23C2E53C-1 | NAME: history_select_23C2E53C_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%TNMAS';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-7FAB6836-1 | NAME: history_select_7FAB6836_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT CASE -- If there is a slash, cut everything after the last slash WHEN INSTR(proposed_canonical_path, '/') > 0 THEN SUBSTR( proposed_canonical_path, 1, LENGTH(proposed_canonical_path) - INSTR(REPLACE(proposed_canonical_path, '/', '\'), '\') + 1 ) -- If no slash exists, it's just a file in the root directory ELSE '/' END AS folder_path, COUNT(*) AS path_count FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' GROUP BY folder_path ORDER BY folder_path DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-56CFA273-1 | NAME: history_select_56CFA273_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
select * from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' and proposed_canonical_path like '%RKN%' order by proposed_canonical_path desc;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A01E0FD1-1 | NAME: history_select_A01E0FD1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT source_path, proposed_canonical_path FROM canonical_plan cp JOIN file_sources fs ON fs.file_id = cp.file_id WHERE cp.proposed_canonical_path LIKE '%/home/harikr/%' OR cp.proposed_canonical_path LIKE '%Migration-Work%' ORDER BY source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A3449AA8-1 | NAME: history_select_A3449AA8_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' and proposed_canonical_path like '%finance%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-1F32E361-1 | NAME: history_select_1F32E361_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%VEHICLE%' AND proposed_canonical_path NOT like '%KWID%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F57ABAE4-1 | NAME: history_select_F57ABAE4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
select * from sys_query_repo limit 10 offset 10;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-1522F321-1 | NAME: history_select_1522F321_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: CO-ROUTINE ImageFolders | SCAN mma | USE TEMP B-TREE FOR DISTINCT | SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SCAN img | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
WITH ImageFolders AS ( SELECT DISTINCT substr( mma.relative_path, 1, length(mma.relative_path) - length(mma.filename) - 1 ) AS source_folder FROM multi_media_assets mma WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' ) SELECT img.source_folder, cp.file_id AS document_file_id, fs.source_path AS document_source_path, COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) AS document_effective_canonical_path FROM ImageFolders img JOIN file_sources fs ON fs.source_path LIKE '/home/harikr/Migration-Work/Tablet-Original/' || img.source_folder || '/%' JOIN canonical_plan cp ON cp.file_id = fs.file_id ORDER BY img.source_folder, document_effective_canonical_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-D1870B00-1 | NAME: history_select_D1870B00_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups
select * from duplicate_groups;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F77D78C9-1 | NAME: history_select_F77D78C9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where manual_canonical_path is not null;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F1F540F4-1 | NAME: history_select_F1F540F4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where current_canonical_path like '%pc%' and proposed_canonical_path like '%Hari%' and proposed_canonical_path like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-BA8C1ACD-1 | NAME: history_select_BA8C1ACD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT COUNT(*) AS remaining_prefixed_paths FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C9E4E435-1 | NAME: history_select_C9E4E435_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'DOWNLOAD_ITR';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-E0757114-1 | NAME: history_select_E0757114_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SEARCH mma USING AUTOMATIC PARTIAL COVERING INDEX (batch_id=? AND source_device_id=? AND category=?) | USE TEMP B-TREE FOR DISTINCT | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
WITH ImageFiles AS ( SELECT mma.inventory_id, mma.relative_path, mma.filename, substr( mma.relative_path, 1, length(mma.relative_path) - length(mma.filename) - 1 ) AS image_source_folder FROM multi_media_assets mma WHERE mma.batch_id = 'NONDOC_20260820_202341' AND mma.source_device_id = 'TABLET' AND mma.category = 'PHOTO' AND ( mma.keep_decision = 'KEEP' OR ( mma.duplicate_status = 'UNIQUE' AND mma.keep_decision IS NULL ) ) ), DocumentFiles AS ( SELECT fs.file_id, substr( fs.source_path, 1, length(fs.source_path) - length(f.filename) - 1 ) AS document_source_folder, substr( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ), 1, length( COALESCE( NULLIF(TRIM(cp.manual_canonical_path), ''), cp.proposed_canonical_path ) ) - length(f.filename) - 1 ) AS document_canonical_folder FROM file_sources fs JOIN files f ON f.file_id = fs.file_id JOIN canonical_plan cp ON cp.file_id = f.file_id ) SELECT DISTINCT i.inventory_id, i.relative_path AS image_source_path, i.image_source_folder, d.document_canonical_folder FROM ImageFiles i JOIN DocumentFiles d ON d.document_source_folder = '/home/harikr/Migration-Work/Tablet-Original/' || i.image_source_folder ORDER BY i.image_source_folder, i.relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-FCEF04F0-1 | NAME: history_select_FCEF04F0_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN files USING COVERING INDEX idx_files_status ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS file_records FROM files;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-23CDDD09-1 | NAME: history_select_23CDDD09_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
SELECT CASE WHEN source_path LIKE '%pictures%' THEN 'Pictures' WHEN source_path LIKE '%movies%' THEN 'Movies' WHEN source_path LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END AS extracted_category, COUNT(*) AS asset_count FROM multi_media_assets -- WHERE batch_id = 'NONDOC_20260820_175117' GROUP BY CASE WHEN source_path LIKE '%pictures%' THEN 'Pictures' WHEN source_path LIKE '%movies%' THEN 'Movies' WHEN source_path LIKE '%music%' THEN 'Music' ELSE 'Unknown/Other' END ORDER BY asset_count DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A2D23BE6-1 | NAME: history_select_A2D23BE6_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN fs USING COVERING INDEX sqlite_autoindex_file_sources_1 | SEARCH cp USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) | SEARCH f USING INTEGER PRIMARY KEY (rowid=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT cp.plan_id, cp.file_id, fs.device_id, fs.source_path, f.filename, cp.current_canonical_path, cp.proposed_canonical_path FROM canonical_plan cp JOIN files f ON f.file_id = cp.file_id JOIN file_sources fs ON fs.file_id = cp.file_id ORDER BY fs.source_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F9290014-1 | NAME: history_select_F9290014_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, manual_canonical_path AS old_path, substr( manual_canonical_path, length('/home/harikr/Master-Repository/PC/') + 1 ) AS new_path FROM canonical_plan WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%' ORDER BY plan_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-A743F047-1 | NAME: history_select_A743F047_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY 2022-23%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-EC9A99EC-1 | NAME: history_select_EC9A99EC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%FY_2024-25%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-088DB3E7-1 | NAME: history_select_088DB3E7_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%work%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-4E9AE889-1 | NAME: history_select_4E9AE889_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select filename, source_path from multi_media_assets where source_device_id ='TABLET' and category ='MUSIC';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-C24F799F-1 | NAME: history_select_C24F799F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan USING COVERING INDEX idx_canonical_plan_proposed ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) FROM canonical_plan WHERE proposed_canonical_path LIKE '%`epsilon%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9D130BDE-1 | NAME: history_select_9D130BDE_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-125493F3-1 | NAME: history_select_125493F3_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT inventory_id, relative_path, filename, category FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND source_device_id = 'TABLET' AND category = 'PHOTO' AND relative_path LIKE '`epsilon/%' ORDER BY relative_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-67767553-1 | NAME: history_select_67767553_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where proposed_canonical_path like '%to-review%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-6BC8CA8F-1 | NAME: history_select_6BC8CA8F_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR GROUP BY
SELECT duplicate_group, SUM( CASE WHEN keep_decision = 'KEEP' THEN 1 ELSE 0 END ) AS keep_count, SUM( CASE WHEN keep_decision = 'EXCLUDE' THEN 1 ELSE 0 END ) AS exclude_count FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL GROUP BY duplicate_group HAVING keep_count <> 1 OR keep_count + exclude_count <> COUNT(*) ORDER BY duplicate_group;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-4771897A-1 | NAME: history_select_4771897A_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
SELECT plan_id, file_id FROM canonical_plan WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%'

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-61531BDB-1 | NAME: history_select_61531BDB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INDEX idx_canonical_plan_status (review_status=?) ⚡ [Optimized: Fast index lookup active]
SELECT COUNT(*) AS review_rows, SUM( CASE WHEN manual_canonical_path IS NOT NULL AND TRIM(manual_canonical_path) <> '' THEN 1 ELSE 0 END ) AS with_manual_path FROM canonical_plan WHERE review_status = 'REVIEW';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-CD58345F-1 | NAME: history_select_CD58345F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: no such table: sys_query_repo)
SELECT * FROM `sys_query_repo` WHERE query_type = 'SELECT' LIMIT 20 OFFSET 100;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-A5ED9160-1 | NAME: history_select_A5ED9160_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT m.source_device_id, m.relative_path, m.filename, m.category, m.size_bytes, m.sha256, m.duplicate_group FROM multi_media_assets m INNER JOIN ( -- This finds the first occurrence of each unique file SELECT sha256, MIN(source_device_id) AS min_device_id FROM multi_media_assets WHERE sha256 IS NOT NULL GROUP BY sha256 ) unique_files ON m.sha256 = unique_files.sha256 AND m.source_device_id = unique_files.min_device_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-5A848954-1 | NAME: history_select_5A848954_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets | USE TEMP B-TREE FOR ORDER BY
SELECT duplicate_group, inventory_id, source_device_id, relative_path, filename, category, size_bytes, datetime(source_modified_at, 'unixepoch', 'localtime') AS modified_at, sha256, keep_decision FROM multi_media_assets WHERE batch_id = 'NONDOC_20260820_202341' AND duplicate_group IS NOT NULL ORDER BY duplicate_group, source_modified_at DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-53C0E9E6-1 | NAME: history_select_53C0E9E6_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
WITH pf_id AS ( SELECT plan_id, file_id FROM canonical_plan WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%' ) SELECT c.proposed_canonical_path AS old_path, REPLACE(c.proposed_canonical_path, 'Vehicle/', 'Vehicle/wego/') AS new_path FROM canonical_plan c INNER JOIN pf_id p ON c.plan_id = p.plan_id AND c.file_id = p.file_id;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9EB3BD00-1 | NAME: history_select_9EB3BD00_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: Dynamic runtime execution mapping required (Details: incomplete input)
SELECT -- Quickly isolates 'Vehicle/' + the next folder name SUBSTR( proposed_canonical_path, 1, INSTR(SUBSTR(proposed_canonical_path, 9), '/') + 8 ) AS folder_path, COUNT(*) AS path_count FROM canonical_plan WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' GROUP BY folder_path ORDER BY folder_path DESC;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical SELECT statement targeting the primary multi_media_assets registry.
-- QUERY ID: Q-SEL-F64FC2AD-1 | NAME: history_select_F64FC2AD_1 | TARGETS: multi_media_assets
-- OPTIMIZER PLAN: Plan Profile: SCAN multi_media_assets
select source_device_id, count(*) from multi_media_assets;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-5E0D8A96-1 | NAME: history_select_5E0D8A96_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH cm USING INDEX idx_manifest_status (status=?) | USE TEMP B-TREE FOR ORDER BY ⚡ [Optimized: Fast index lookup active]
SELECT cm.manifest_id, cm.file_id, cm.source_device_id, cm.source_path, cm.destination_path, cm.source_size_bytes, cm.source_sha256, cm.status FROM copy_manifest cm WHERE cm.status = 'PLANNED' ORDER BY cm.destination_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-85D0223B-1 | NAME: history_select_85D0223B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
select * from canonical_plan where proposed_canonical_path like '%Hari%' and plan_id in (11, 227);

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-F77D78C9-2 | NAME: history_select_F77D78C9_2 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
select * from canonical_plan where manual_canonical_path is not null;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-16FBE95E-1 | NAME: history_select_16FBE95E_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN duplicate_groups | USE TEMP B-TREE FOR GROUP BY
SELECT decision, COUNT(*) AS groups FROM duplicate_groups GROUP BY decision;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-8E9B554B-1 | NAME: history_select_8E9B554B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan | USE TEMP B-TREE FOR GROUP BY | USE TEMP B-TREE FOR ORDER BY
SELECT COALESCE( NULLIF(TRIM(manual_canonical_path), ''), proposed_canonical_path ) AS effective_canonical_path, COUNT(*) AS file_count, GROUP_CONCAT(file_id, ', ') AS file_ids FROM canonical_plan GROUP BY effective_canonical_path HAVING COUNT(*) > 1 ORDER BY file_count DESC, effective_canonical_path;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-SEL-9402EF85-1 | NAME: history_select_9402EF85_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH duplicate_groups USING INDEX sqlite_autoindex_duplicate_groups_1 (duplicate_group_id=?) ⚡ [Optimized: Fast index lookup active]
SELECT duplicate_group_id, decision, chosen_file_id, notes FROM duplicate_groups WHERE duplicate_group_id = 'DUP-0011';