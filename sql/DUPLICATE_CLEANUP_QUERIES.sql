-- ============================================================
-- DUPLICATE SOURCE CLEANUP
-- ============================================================

-- 1. Candidates that the cleanup script will consider.
SELECT
    dg.duplicate_group_id,
    f.file_id,
    fs.device_id,
    f.filename,
    fs.source_path,
    f.sha256,
    cm.destination_path AS verified_master_path
FROM duplicate_groups dg
JOIN duplicate_members dm
    ON dm.duplicate_group_id = dg.duplicate_group_id
JOIN files f
    ON f.file_id = dm.file_id
JOIN file_sources fs
    ON fs.file_id = f.file_id
JOIN copy_manifest cm
    ON cm.file_id = dg.chosen_file_id
   AND cm.status = 'VERIFIED'
WHERE dg.decision = 'KEEP_ONE'
  AND f.file_id <> dg.chosen_file_id
ORDER BY dg.duplicate_group_id, fs.device_id, fs.source_path;


-- 2. Number of non-chosen duplicate source records.
SELECT COUNT(*) AS non_chosen_duplicates
FROM duplicate_groups dg
JOIN duplicate_members dm
    ON dm.duplicate_group_id = dg.duplicate_group_id
WHERE dg.decision = 'KEEP_ONE'
  AND dm.file_id <> dg.chosen_file_id;


-- 3. Deletion/bin history.
SELECT
    deletion_id,
    file_id,
    device_id,
    original_path,
    bin_path,
    deleted_at,
    reason,
    sha256
FROM deletion_events
ORDER BY deleted_at DESC;


-- 4. Files currently in the bin.
SELECT
    file_id,
    filename,
    storage_state,
    size_bytes,
    sha256
FROM files
WHERE storage_state = 'IN_BIN'
ORDER BY filename;


-- 5. Storage state summary.
SELECT
    storage_state,
    COUNT(*) AS file_count,
    SUM(size_bytes) AS total_bytes
FROM files
GROUP BY storage_state
ORDER BY storage_state;


-- 6. Confirm every bin record has a deletion event.
SELECT COUNT(*) AS bin_without_event
FROM files f
LEFT JOIN deletion_events de
    ON de.file_id = f.file_id
WHERE f.storage_state = 'IN_BIN'
  AND de.deletion_id IS NULL;


-- 7. Confirm bin events still point to intact hashes.
SELECT
    de.file_id,
    de.device_id,
    de.bin_path,
    de.sha256,
    f.sha256 AS catalog_sha256
FROM deletion_events de
JOIN files f
    ON f.file_id = de.file_id
WHERE f.storage_state = 'IN_BIN'
  AND de.sha256 <> f.sha256;
