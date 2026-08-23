-- ============================================================
-- CANONICAL PATH / STORAGE STATE QUERIES
-- ============================================================

-- 1. Current storage state
SELECT
    storage_state,
    COUNT(*) AS file_count
FROM files
GROUP BY storage_state
ORDER BY storage_state;

-- 2. Files currently in master
SELECT
    file_id,
    filename,
    canonical_path,
    master_path,
    storage_state
FROM files
WHERE storage_state='IN_MASTER'
ORDER BY canonical_path;

-- 3. Files moved out of master
SELECT
    file_id,
    filename,
    canonical_path,
    master_path,
    storage_state,
    external_device_id,
    external_path,
    moved_out_at,
    storage_move_reason,
    sha256,
    size_bytes
FROM files
WHERE storage_state='MOVED_EXTERNAL'
ORDER BY moved_out_at DESC;

-- 4. Storage states with total size
SELECT
    storage_state,
    COUNT(*) AS file_count,
    SUM(size_bytes) AS total_bytes
FROM files
GROUP BY storage_state
ORDER BY storage_state;

-- 5. Files whose physical master path differs from canonical path
SELECT
    file_id,
    filename,
    canonical_path,
    master_path,
    storage_state
FROM files
WHERE canonical_path <> master_path
ORDER BY canonical_path;

-- 6. Files that are expected in master but physically missing
-- This query only detects stale catalog state when the storage checker
-- has marked a file MISSING.
SELECT
    file_id,
    filename,
    canonical_path,
    master_path,
    storage_state
FROM files
WHERE storage_state='MISSING'
ORDER BY canonical_path;
