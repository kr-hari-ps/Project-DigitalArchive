-- ============================================================
-- MULTIMEDIA PHYSICAL COPY VERIFICATION
-- ============================================================

-- 1. Status summary
SELECT
    status,
    COUNT(*) AS file_count,
    SUM(source_size_bytes) AS total_bytes
FROM media_copy_manifest
WHERE batch_id=:manifest_batch_id
GROUP BY status
ORDER BY status;


-- 2. Expected clean final state
SELECT
    COUNT(*) AS verified_rows,
    COUNT(DISTINCT inventory_id) AS distinct_inventory,
    COUNT(DISTINCT destination_path) AS distinct_destinations
FROM media_copy_manifest
WHERE batch_id=:manifest_batch_id
  AND status='VERIFIED';


-- 3. Hash mismatches
SELECT COUNT(*) AS hash_mismatches
FROM media_copy_manifest
WHERE batch_id=:manifest_batch_id
  AND status='VERIFIED'
  AND source_sha256 <> destination_sha256;


-- 4. Failed rows
SELECT
    manifest_id,
    inventory_id,
    source_device_id,
    source_path,
    destination_path,
    status,
    error_message
FROM media_copy_manifest
WHERE batch_id=:manifest_batch_id
  AND status='FAILED'
ORDER BY manifest_id;


-- 5. Verified media files
SELECT
    manifest_id,
    inventory_id,
    category,
    source_device_id,
    source_path,
    destination_path,
    source_sha256,
    destination_sha256,
    verified_at
FROM media_copy_manifest
WHERE batch_id=:manifest_batch_id
  AND status='VERIFIED'
ORDER BY destination_path;
