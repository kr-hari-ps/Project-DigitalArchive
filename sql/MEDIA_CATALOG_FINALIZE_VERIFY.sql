-- MEDIA CATALOG FINALIZATION VERIFICATION
SELECT COUNT(*) AS reviewed_applied
FROM multi_media_assets mma
JOIN media_canonical_move_manifest mcm
  ON mcm.inventory_id=mma.inventory_id
 AND mcm.batch_id='MEDIA_CANONICAL_20260823'
 AND mcm.status='APPLIED'
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>'';

SELECT canonical_path,COUNT(*) AS file_count,GROUP_CONCAT(file_id,', ') AS file_ids
FROM files
WHERE storage_state='IN_MASTER' AND status='MASTER'
GROUP BY canonical_path HAVING COUNT(*)>1;

SELECT COUNT(*) AS missing_source_rows
FROM multi_media_assets mma
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>''
  AND NOT EXISTS (
    SELECT 1 FROM file_sources fs
    JOIN files f ON f.file_id=fs.file_id
    WHERE f.sha256=mma.sha256
      AND fs.device_id=mma.source_device_id
      AND fs.source_path=mma.source_path
  );

SELECT COUNT(*) AS missing_verified_manifest_rows
FROM multi_media_assets mma
WHERE mma.batch_id='NONDOC_20260820_202341'
  AND mma.manual_canonical_path IS NOT NULL
  AND TRIM(mma.manual_canonical_path)<>''
  AND NOT EXISTS (
    SELECT 1 FROM copy_manifest cm
    JOIN files f ON f.file_id=cm.file_id
    WHERE f.sha256=mma.sha256
      AND cm.source_device_id=mma.source_device_id
      AND cm.source_path=mma.source_path
      AND cm.destination_path='/home/harikr/Master-Repository/'||mma.manual_canonical_path
      AND cm.status='VERIFIED'
  );

SELECT sha256,COUNT(*) AS master_count,GROUP_CONCAT(file_id,', ') AS file_ids
FROM files
WHERE storage_state='IN_MASTER' AND status='MASTER'
GROUP BY sha256 HAVING COUNT(*)>1;
