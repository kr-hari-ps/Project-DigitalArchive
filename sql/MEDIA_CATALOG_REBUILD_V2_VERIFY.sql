SELECT COUNT(*) AS rebuild_rows
FROM multi_media_assets
WHERE batch_id='NONDOC_20260820_202341'
  AND manual_canonical_path IS NOT NULL
  AND TRIM(manual_canonical_path)<>''
  AND inventory_id NOT IN (2616,3670,3671,3672,3673,3674);

SELECT COUNT(*) AS missing_master_identity
FROM multi_media_assets mma
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>''
  AND mma.inventory_id NOT IN (2616,3670,3671,3672,3673,3674)
  AND NOT EXISTS (
    SELECT 1 FROM files f
    WHERE f.sha256=mma.sha256
      AND f.canonical_path=mma.manual_canonical_path
      AND f.storage_state='IN_MASTER'
      AND f.status='MASTER'
  );

SELECT COUNT(*) AS missing_source_provenance
FROM multi_media_assets mma
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>''
  AND mma.inventory_id NOT IN (2616,3670,3671,3672,3673,3674)
  AND NOT EXISTS (
    SELECT 1
    FROM file_sources fs
    JOIN files f ON f.file_id=fs.file_id
    WHERE f.sha256=mma.sha256
      AND fs.device_id=mma.source_device_id
      AND fs.source_path=mma.source_path
  );

SELECT COUNT(*) AS missing_verified_manifest
FROM multi_media_assets mma
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>''
  AND mma.inventory_id NOT IN (2616,3670,3671,3672,3673,3674)
  AND NOT EXISTS (
    SELECT 1
    FROM copy_manifest cm
    JOIN files f ON f.file_id=cm.file_id
    WHERE f.sha256=mma.sha256
      AND cm.device_id=mma.source_device_id
      AND cm.source_path=mma.source_path
      AND cm.destination_path='/home/harikr/Master-Repository/'||mma.manual_canonical_path
      AND cm.status='VERIFIED'
  );

SELECT canonical_path,COUNT(*) AS file_count,GROUP_CONCAT(file_id,', ') AS file_ids
FROM files
WHERE storage_state='IN_MASTER' AND status='MASTER'
GROUP BY canonical_path HAVING COUNT(*)>1 ORDER BY canonical_path;
