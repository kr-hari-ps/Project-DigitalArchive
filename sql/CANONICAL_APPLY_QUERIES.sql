-- ============================================================
-- CANONICAL APPLY / VERIFICATION QUERIES
-- ============================================================

SELECT
    review_status,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY review_status
ORDER BY review_status;

SELECT COUNT(*) AS collisions
FROM (
    SELECT canonical_path
    FROM files
    WHERE storage_state='IN_MASTER'
    GROUP BY canonical_path
    HAVING COUNT(*) > 1
);

SELECT COUNT(*) AS hash_mismatches
FROM copy_manifest
WHERE verification_method='SHA256_AFTER_CANONICAL_MOVE'
  AND status='VERIFIED'
  AND source_sha256<>destination_sha256;

SELECT
    file_id,
    filename,
    master_path,
    canonical_path,
    storage_state
FROM files
WHERE storage_state='IN_MASTER'
  AND master_path<>canonical_path
ORDER BY canonical_path;

SELECT
    cp.plan_id,
    cp.file_id,
    f.filename,
    CASE
        WHEN NULLIF(TRIM(cp.manual_canonical_path), '') IS NOT NULL
            THEN 'MANUAL'
        WHEN NULLIF(TRIM(cp.proposed_canonical_path), '') IS NOT NULL
            THEN 'PROPOSED_ONLY'
        ELSE 'NO_PATH'
    END AS path_source,
    COALESCE(
        NULLIF(TRIM(cp.manual_canonical_path), ''),
        cp.proposed_canonical_path
    ) AS effective_canonical_path
FROM canonical_plan cp
JOIN files f ON f.file_id=cp.file_id
WHERE cp.review_status='REVIEW'
ORDER BY cp.plan_id;
