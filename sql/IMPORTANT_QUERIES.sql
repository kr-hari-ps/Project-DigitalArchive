-- Non-document inventory is initially a CSV review dataset.
-- These SQLite queries can be used after import to the archive catalog.

-- Example category summary
SELECT media_category, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes
FROM non_document_inventory
GROUP BY media_category
ORDER BY file_count DESC;

-- Exact duplicate groups
SELECT duplicate_group, COUNT(*) AS members
FROM non_document_inventory
WHERE duplicate_group <> ''
GROUP BY duplicate_group
ORDER BY duplicate_group;

-- Device/category summary
SELECT source, media_category, COUNT(*) AS file_count, SUM(size_bytes) AS total_bytes
FROM non_document_inventory
GROUP BY source, media_category
ORDER BY source, media_category;
