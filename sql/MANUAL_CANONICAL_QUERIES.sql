-- ============================================================
-- MANUAL CANONICAL PATH REVIEW
-- ============================================================

-- 1. Review conservative entries and manual fields.
SELECT
    cp.plan_id,
    cp.file_id,
    fs.device_id,
    fs.source_path,
    f.filename,
    cp.proposed_canonical_path,
    cp.manual_canonical_path,
    cp.manual_category,
    cp.manual_notes,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id = cp.file_id
JOIN file_sources fs ON fs.file_id = cp.file_id
WHERE cp.proposal_rule = 'CONSERVATIVE_REVIEW'
ORDER BY fs.source_path;

-- 2. Example manual update.
-- UPDATE canonical_plan
-- SET manual_canonical_path =
--         'Documents/Personal/Identity_n_Accounts/Aadhar/EAadhaar_....pdf',
--     manual_category = 'Aadhar',
--     manual_notes = 'Identity document from tablet Download'
-- WHERE plan_id = 123;

-- 3. Rows still awaiting manual classification.
SELECT
    cp.plan_id,
    cp.file_id,
    fs.device_id,
    fs.source_path,
    f.filename,
    cp.proposed_canonical_path,
    cp.manual_category,
    cp.manual_canonical_path,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id = cp.file_id
JOIN file_sources fs ON fs.file_id = cp.file_id
WHERE cp.review_status = 'REVIEW'
  AND (
      cp.manual_canonical_path IS NULL
      OR TRIM(cp.manual_canonical_path) = ''
  )
ORDER BY fs.source_path;

-- 4. Manually classified rows.
SELECT
    cp.plan_id,
    cp.file_id,
    f.filename,
    cp.manual_category,
    cp.manual_canonical_path,
    cp.manual_notes,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id = cp.file_id
WHERE cp.manual_canonical_path IS NOT NULL
  AND TRIM(cp.manual_canonical_path) <> ''
ORDER BY cp.manual_category, cp.manual_canonical_path;

-- 5. Classification counts.
SELECT
    COALESCE(NULLIF(TRIM(manual_category), ''), '[UNCLASSIFIED]') AS category,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY COALESCE(NULLIF(TRIM(manual_category), ''), '[UNCLASSIFIED]')
ORDER BY file_count DESC;

-- 6. Potential destination collisions.
SELECT
    COALESCE(
        NULLIF(TRIM(manual_canonical_path), ''),
        proposed_canonical_path
    ) AS target_path,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY target_path
HAVING COUNT(*) > 1
ORDER BY file_count DESC, target_path;

-- 7. Effective destination to be used later.
SELECT
    cp.plan_id,
    cp.file_id,
    f.filename,
    COALESCE(
        NULLIF(TRIM(cp.manual_canonical_path), ''),
        cp.proposed_canonical_path
    ) AS effective_canonical_path,
    cp.manual_category,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id = cp.file_id
ORDER BY effective_canonical_path;

-- 8. Conservative entries with no manual destination yet.
SELECT COUNT(*) AS unclassified_conservative
FROM canonical_plan
WHERE proposal_rule = 'CONSERVATIVE_REVIEW'
  AND (
      manual_canonical_path IS NULL
      OR TRIM(manual_canonical_path) = ''
  );
