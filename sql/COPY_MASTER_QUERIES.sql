-- PHYSICAL MASTER COPY QUERIES

-- 1. Copy status
SELECT status, COUNT(*) AS file_count
FROM copy_manifest
GROUP BY status
ORDER BY status;

-- 2. Any failed/unverified copies
SELECT
    manifest_id,
    file_id,
    source_device_id,
    source_path,
    destination_path,
    status,
    error_message
FROM copy_manifest
WHERE status IN ('PLANNED','COPIED','FAILED')
ORDER BY manifest_id;

-- 3. Hash verification
SELECT COUNT(*) AS mismatches
FROM copy_manifest
WHERE status='VERIFIED'
  AND source_sha256 <> destination_sha256;

-- 4. Verified copies
SELECT
    manifest_id,
    file_id,
    source_device_id,
    source_path,
    destination_path,
    source_sha256,
    destination_sha256,
    verified_at
FROM copy_manifest
WHERE status='VERIFIED'
ORDER BY destination_path;

-- 5. Destination collisions are prohibited; this should return zero.
SELECT
    destination_path,
    COUNT(*) AS records
FROM copy_manifest
GROUP BY destination_path
HAVING COUNT(*) > 1;

-- 6. Files with xattrs applied
SELECT
    f.file_id,
    f.filename,
    f.master_path,
    fx.xattr_supported,
    fx.xattr_applied,
    fx.xattr_names
FROM files f
JOIN file_xattrs fx ON fx.file_id=f.file_id
WHERE fx.xattr_applied=1
ORDER BY f.master_path;

-- 7. Folder/device summary
SELECT
    master_path,
    folder_type,
    device_summary,
    description
FROM folders
ORDER BY master_path;
