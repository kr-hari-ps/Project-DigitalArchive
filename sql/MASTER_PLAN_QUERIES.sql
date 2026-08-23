-- MASTER COPY PLAN QUERIES

-- 1. Planned copy count
SELECT status, COUNT(*) AS file_count
FROM copy_manifest
GROUP BY status
ORDER BY status;

-- 2. Validate uniqueness of the plan
SELECT
    COUNT(*) AS manifest_rows,
    COUNT(DISTINCT file_id) AS distinct_files,
    COUNT(DISTINCT destination_path) AS distinct_destinations
FROM copy_manifest
WHERE status='PLANNED';

-- 3. Review complete planned manifest
SELECT
    manifest_id,
    file_id,
    source_device_id,
    source_path,
    destination_path,
    source_size_bytes,
    source_sha256,
    status,
    notes
FROM copy_manifest
WHERE status='PLANNED'
ORDER BY destination_path;

-- 4. Planned files by source device
SELECT
    source_device_id,
    COUNT(*) AS file_count,
    SUM(source_size_bytes) AS total_bytes
FROM copy_manifest
WHERE status='PLANNED'
GROUP BY source_device_id
ORDER BY source_device_id;

-- 5. Planned duplicate-group choices
SELECT
    cm.manifest_id,
    cm.file_id,
    dg.duplicate_group_id,
    dg.chosen_file_id,
    cm.source_device_id,
    cm.source_path,
    cm.destination_path
FROM copy_manifest cm
JOIN duplicate_members dm
    ON dm.file_id=cm.file_id
JOIN duplicate_groups dg
    ON dg.duplicate_group_id=dm.duplicate_group_id
WHERE cm.status='PLANNED'
ORDER BY dg.duplicate_group_id;
