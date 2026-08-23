-- ============================================================
-- CANONICAL PATH PLANNING QUERIES
-- ============================================================

-- 1. Plan summary
SELECT
    review_status,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY review_status
ORDER BY review_status;

-- 2. Complete canonical plan
SELECT
    cp.plan_id,
    cp.file_id,
    f.filename,
    f.sha256,
    cp.current_canonical_path,
    cp.proposed_canonical_path,
    cp.proposal_rule,
    cp.proposal_reason,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id=cp.file_id
ORDER BY cp.proposed_canonical_path;

-- 3. Review by rule
SELECT
    proposal_rule,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY proposal_rule
ORDER BY file_count DESC;

-- 4. Potential destination collisions
SELECT
    proposed_canonical_path,
    COUNT(*) AS file_count
FROM canonical_plan
GROUP BY proposed_canonical_path
HAVING COUNT(*) > 1
ORDER BY file_count DESC, proposed_canonical_path;

-- 5. Plans needing manual review
SELECT
    cp.plan_id,
    cp.file_id,
    f.filename,
    cp.current_canonical_path,
    cp.proposed_canonical_path,
    cp.proposal_rule,
    cp.proposal_reason
FROM canonical_plan cp
JOIN files f ON f.file_id=cp.file_id
WHERE cp.review_status='REVIEW'
ORDER BY cp.proposal_rule, cp.proposed_canonical_path;

-- 6. Example: inspect ITR plans
SELECT
    cp.plan_id,
    f.filename,
    cp.proposed_canonical_path,
    cp.proposal_rule,
    cp.review_status
FROM canonical_plan cp
JOIN files f ON f.file_id=cp.file_id
WHERE cp.proposed_canonical_path LIKE 'Documents/Finance/ITR/%'
ORDER BY cp.proposed_canonical_path;
