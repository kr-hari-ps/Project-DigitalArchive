-- ============================================================
-- BEEKEEPER WORKSPACE TAB: UPDATE OPERATIONS
-- Total Scripts in this Tab: 22
-- ============================================================

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-9ADD3718-1 | NAME: history_update_9ADD3718_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'FY 2025-26/', 'FY_2025-26/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%FY 2025-26%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-C76046D4-1 | NAME: history_update_C76046D4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INDEX sqlite_autoindex_canonical_plan_1 (file_id=?) ⚡ [Optimized: Fast index lookup active]
UPDATE canonical_plan SET manual_canonical_path = 'Documents/Personal/Hospital/Medisep_claims/claim_compare-WPS Office_2.xlsx', manual_category = 'Medical', manual_notes = 'Different-content second copy of claim_compare-WPS Office.xlsx; retained separately.' WHERE file_id = 65;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-A774A681-1 | NAME: history_update_A774A681_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Work/', 'Work/EPFO/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-0BD33CAC-1 | NAME: history_update_0BD33CAC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Work/', 'Work/Cognizant/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%Hari%' and plan_id=246;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-AAE1CEEB-1 | NAME: history_update_AAE1CEEB_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET manual_canonical_path = substr( manual_canonical_path, length('/home/harikr/Master-Repository/PC/') + 1 ), updated_at = CURRENT_TIMESTAMP WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/PC/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-7FFEA597-1 | NAME: history_update_7FFEA597_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET manual_canonical_path = substr( manual_canonical_path, length('/home/harikr/Master-Repository/TABLET/') + 1 ), updated_at = CURRENT_TIMESTAMP WHERE manual_canonical_path LIKE '/home/harikr/Master-Repository/TABLET/%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-F08686FD-1 | NAME: history_update_F08686FD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Documents/_Review-NonPersonal/', 'Electronics/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'NON_PERSONAL_REVIEW' and proposed_canonical_path not like '%cloud%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-1AAD0AE1-1 | NAME: history_update_1AAD0AE1_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Work/', 'Work/Certs_Resumes/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%Hari%' and plan_id=227;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-64719AC2-1 | NAME: history_update_64719AC2_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'FY 2023-24/', 'FY_2023-24/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%FY 2023-24%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-F1F5101B-1 | NAME: history_update_F1F5101B_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'Achan/', 'RKN/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%ACHAN%' and proposed_canonical_path not like '%SKP%' and proposed_canonical_path not like '%HKR%' and proposed_canonical_path not like '%RKN%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-C0390906-1 | NAME: history_update_C0390906_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Personal/', 'Personal/Bills_n_Payments/Temple/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PERSONAL_DOCS' and plan_id in (80, 109);

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-D36C1997-1 | NAME: history_update_D36C1997_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Personal/', 'Personal/Meds/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PERSONAL_DOCS' and plan_id = 59;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-F89440A4-1 | NAME: history_update_F89440A4_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'FY 2022-23/', 'FY_2022-23/HKR/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%FY 2022-23%' and proposed_canonical_path not like '%SKP%' and proposed_canonical_path not like '%HKR%' and proposed_canonical_path not like '%RKN%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-3F5A7B82-1 | NAME: history_update_3F5A7B82_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Work/', 'Personal/Identity_n_Accounts/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%HariPAN%' and plan_id=288;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-401FD002-1 | NAME: history_update_401FD002_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'FY 2024-25/', 'FY_2024-25/HKR/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%finance%' AND proposed_canonical_path LIKE '%FY 2024-25%' and proposed_canonical_path not like '%SKP%' and proposed_canonical_path not like '%HKR%' and proposed_canonical_path not like '%RKN%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-6E2858B8-1 | NAME: history_update_6E2858B8_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SEARCH canonical_plan USING INTEGER PRIMARY KEY (rowid=?)
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Personal/', 'Work/Certs_Resumes/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%Hari%' and plan_id=11;

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-227057BD-1 | NAME: history_update_227057BD_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'FY-2025-26/', 'FY_2025-26/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'PRESERVE_PC_ITR_STRUCTURE' and proposed_canonical_path like '%finance%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-0CDBCC07-1 | NAME: history_update_0CDBCC07_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Work/', 'Work/Cognizant/'), updated_at = CURRENT_TIMESTAMP where proposed_canonical_path like '%Work/%' and current_canonical_path like '%PC%' and proposed_canonical_path not like '%Hari%' and proposed_canonical_path not like '%TNMAS%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-595C14D9-1 | NAME: history_update_595C14D9_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set proposed_canonical_path = replace(proposed_canonical_path, 'Documents/_Review-NonPersonal/', 'Cloud/'), updated_at = CURRENT_TIMESTAMP where proposal_rule = 'NON_PERSONAL_REVIEW' and proposed_canonical_path like '%google%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-BDA674CC-1 | NAME: history_update_BDA674CC_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = replace(proposed_canonical_path, '`epsilon/', ''), updated_at = CURRENT_TIMESTAMP WHERE proposal_rule = 'PRESERVE_TABLET_PERSONAL_STRUCTURE' AND proposed_canonical_path LIKE '%`epsilon%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-0D41EE47-1 | NAME: history_update_0D41EE47_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
update canonical_plan set manual_canonical_path = replace(manual_canonical_path, 'Hospital/', 'Meds/') where proposal_rule = 'DOWNLOAD_TO_REVIEW' and manual_canonical_path like '%janaushadi%';

-- ------------------------------------------------------------

-- USER DESCRIPTION: Historical administrative metadata processing loop.
-- QUERY ID: Q-UPD-DD64B79F-1 | NAME: history_update_DD64B79F_1 | TARGETS: system_metadata
-- OPTIMIZER PLAN: Plan Profile: SCAN canonical_plan
UPDATE canonical_plan SET proposed_canonical_path = REPLACE(proposed_canonical_path, 'Vehicle/', 'Vehicle/wego/'), updated_at = CURRENT_TIMESTAMP WHERE proposed_canonical_path LIKE '%Vehicle%' AND proposed_canonical_path NOT LIKE '%kwid%';