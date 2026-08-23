-- MULTIMEDIA ASSET REVIEW QUERIES v2
-- Use :batch_id = actual loader batch.

SELECT category,COUNT(*) AS file_count,SUM(size_bytes) AS total_bytes
FROM multi_media_assets WHERE batch_id=:batch_id
GROUP BY category ORDER BY file_count DESC,category;

SELECT COALESCE(keep_decision,'[REVIEW]') AS keep_decision,COUNT(*) AS file_count
FROM multi_media_assets WHERE batch_id=:batch_id
GROUP BY COALESCE(keep_decision,'[REVIEW]');

SELECT inventory_id,source_device_id,relative_path,filename,category,keep_decision,manual_notes
FROM multi_media_assets
WHERE batch_id=:batch_id AND category='DERIVED_CACHE'
ORDER BY source_device_id,relative_path;

SELECT duplicate_group,COUNT(*) AS member_count,
       GROUP_CONCAT(source_device_id||'|'||relative_path,CHAR(10)) AS members
FROM multi_media_assets
WHERE batch_id=:batch_id AND duplicate_group IS NOT NULL
GROUP BY duplicate_group ORDER BY duplicate_group;

SELECT inventory_id,duplicate_group,source_device_id,relative_path,filename,category,size_bytes,sha256,keep_decision
FROM multi_media_assets
WHERE batch_id=:batch_id AND duplicate_group IS NOT NULL
ORDER BY duplicate_group,source_device_id,relative_path;

SELECT inventory_id,source_device_id,relative_path,filename,category,size_bytes,sha256,duplicate_group,duplicate_status,keep_decision,manual_category,manual_canonical_path,manual_notes
FROM multi_media_assets
WHERE batch_id=:batch_id AND category<>'DERIVED_CACHE'
ORDER BY category,source_device_id,relative_path;
