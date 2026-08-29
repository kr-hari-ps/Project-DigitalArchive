PRAGMA foreign_keys = ON;

-- ============================================================
-- Core device identity
-- ============================================================

CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    device_uuid TEXT NOT NULL UNIQUE,
    device_name TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL,
    manufacturer TEXT,
    model TEXT,
    os_name TEXT,
    os_version TEXT,
    description TEXT,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_identifiers (
    identifier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    identifier_type TEXT NOT NULL,
    identifier_value TEXT NOT NULL,
    is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
    first_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TEXT,
    notes TEXT,
    UNIQUE (identifier_type, identifier_value),
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- ============================================================
-- Logical files and source provenance
-- ============================================================

CREATE TABLE IF NOT EXISTS files (
    file_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sha256 TEXT NOT NULL,
    master_path TEXT,
    canonical_path TEXT,
    filename TEXT NOT NULL,
    extension TEXT,
    size_bytes INTEGER NOT NULL,
    media_type TEXT,
    capture_date TEXT,
    created_date TEXT,
    modified_date TEXT,
    status TEXT NOT NULL DEFAULT 'MASTER',
    storage_state TEXT NOT NULL DEFAULT 'IN_MASTER'
        CHECK (storage_state IN ('IN_MASTER', 'MOVED_EXTERNAL', 'IN_BIN', 'MISSING')),
    external_device_id TEXT,
    external_path TEXT,
    moved_out_at TEXT,
    storage_move_reason TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (sha256, master_path)
);

CREATE TABLE IF NOT EXISTS file_sources (
    file_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    source_path TEXT,
    source_filename TEXT,
    source_size_bytes INTEGER,
    source_sha256 TEXT NOT NULL,
    source_modified_date TEXT,
    first_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (file_id, device_id, source_path),
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- ============================================================
-- Restore policy
-- ============================================================

CREATE TABLE IF NOT EXISTS restore_preferences (
    file_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    restore_enabled INTEGER NOT NULL DEFAULT 1 CHECK (restore_enabled IN (0, 1)),
    target_relative_path TEXT,
    notes TEXT,
    PRIMARY KEY (file_id, device_id),
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- ============================================================
-- Duplicate management
-- ============================================================

CREATE TABLE IF NOT EXISTS duplicate_groups (
    duplicate_group_id TEXT PRIMARY KEY,
    sha256 TEXT NOT NULL,
    decision TEXT NOT NULL DEFAULT 'REVIEW'
        CHECK (decision IN ('REVIEW', 'KEEP_ONE', 'KEEP_ALL', 'IGNORE')),
    chosen_file_id INTEGER,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chosen_file_id) REFERENCES files(file_id)
);

CREATE TABLE IF NOT EXISTS duplicate_members (
    duplicate_group_id TEXT NOT NULL,
    file_id INTEGER NOT NULL,
    PRIMARY KEY (duplicate_group_id, file_id),
    FOREIGN KEY (duplicate_group_id) REFERENCES duplicate_groups(duplicate_group_id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS deletion_events (
    deletion_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER,
    device_id TEXT NOT NULL,
    original_path TEXT,
    deleted_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bin_path TEXT,
    reason TEXT,
    sha256 TEXT,
    notes TEXT,
    FOREIGN KEY (file_id) REFERENCES files(file_id),
    FOREIGN KEY (device_id) REFERENCES devices(device_id)
);

-- ============================================================
-- MASTER/catalog support
-- ============================================================

CREATE TABLE IF NOT EXISTS folders (
    folder_id INTEGER PRIMARY KEY AUTOINCREMENT,
    master_path TEXT NOT NULL UNIQUE,
    folder_name TEXT NOT NULL,
    parent_path TEXT,
    folder_type TEXT,
    description TEXT,
    device_summary TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS copy_manifest (
    manifest_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER NOT NULL,
    source_device_id TEXT NOT NULL,
    source_path TEXT NOT NULL,
    destination_path TEXT NOT NULL,
    source_sha256 TEXT NOT NULL,
    destination_sha256 TEXT,
    source_size_bytes INTEGER,
    destination_size_bytes INTEGER,
    copied_at TEXT,
    verified_at TEXT,
    status TEXT NOT NULL DEFAULT 'PLANNED'
        CHECK (status IN ('PLANNED', 'COPIED', 'VERIFIED', 'FAILED', 'SKIPPED')),
    verification_method TEXT,
    error_message TEXT,
    notes TEXT,
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE,
    FOREIGN KEY (source_device_id) REFERENCES devices(device_id)
);

CREATE TABLE IF NOT EXISTS file_xattrs (
    file_id INTEGER PRIMARY KEY,
    xattr_supported INTEGER NOT NULL DEFAULT 0 CHECK (xattr_supported IN (0, 1)),
    xattr_applied INTEGER NOT NULL DEFAULT 0 CHECK (xattr_applied IN (0, 1)),
    xattr_names TEXT,
    last_checked_at TEXT,
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE
);

-- ============================================================
-- Historical canonical planning
-- ============================================================

CREATE TABLE IF NOT EXISTS canonical_plan (
    plan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id INTEGER NOT NULL UNIQUE,
    current_canonical_path TEXT,
    proposed_canonical_path TEXT NOT NULL,
    proposal_rule TEXT,
    proposal_reason TEXT,
    review_status TEXT NOT NULL DEFAULT 'REVIEW'
        CHECK (review_status IN ('REVIEW', 'APPROVED', 'REJECTED', 'APPLIED')),
    reviewed_at TEXT,
    reviewed_by TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    manual_canonical_path TEXT,
    manual_category TEXT,
    manual_notes TEXT,
    FOREIGN KEY (file_id) REFERENCES files(file_id) ON DELETE CASCADE
);

-- ============================================================
-- Media catalog and metadata
-- ============================================================

CREATE TABLE IF NOT EXISTS multi_media_assets (
    inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id TEXT NOT NULL,
    source_device_id TEXT NOT NULL,
    source_path TEXT NOT NULL,
    relative_path TEXT,
    filename TEXT NOT NULL,
    extension TEXT,
    category TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    sha256 TEXT NOT NULL,
    duplicate_group TEXT,
    duplicate_status TEXT,
    keep_decision TEXT,
    proposed_category TEXT,
    proposed_canonical_path TEXT,
    manual_category TEXT,
    manual_canonical_path TEXT,
    manual_notes TEXT,
    source_created_at TEXT,
    source_modified_at TEXT,
    source_accessed_at TEXT,
    source_ctime_at TEXT,
    duplicate_reason TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS media_metadata (
    inventory_id INTEGER PRIMARY KEY,
    mime_type TEXT,
    width INTEGER,
    height INTEGER,
    orientation TEXT,
    duration_seconds REAL,
    bitrate INTEGER,
    sample_rate INTEGER,
    codec TEXT,
    camera_make TEXT,
    camera_model TEXT,
    capture_date TEXT,
    artist TEXT,
    album TEXT,
    title TEXT,
    metadata_json TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inventory_id) REFERENCES multi_media_assets(inventory_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS media_copy_manifest (
    manifest_id INTEGER PRIMARY KEY AUTOINCREMENT,
    batch_id TEXT NOT NULL,
    inventory_id INTEGER NOT NULL,
    source_device_id TEXT NOT NULL,
    source_path TEXT NOT NULL,
    destination_path TEXT,
    source_sha256 TEXT NOT NULL,
    destination_sha256 TEXT,
    source_size_bytes INTEGER NOT NULL,
    destination_size_bytes INTEGER,
    category TEXT NOT NULL,
    copied_at TEXT,
    verified_at TEXT,
    status TEXT NOT NULL DEFAULT 'PLANNED'
        CHECK (status IN ('PLANNED', 'COPIED', 'VERIFIED', 'FAILED', 'SKIPPED')),
    verification_method TEXT,
    error_message TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inventory_id) REFERENCES multi_media_assets(inventory_id) ON DELETE CASCADE
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_devices_active
    ON devices(active);

CREATE INDEX IF NOT EXISTS idx_device_identifiers_device
    ON device_identifiers(device_id);

CREATE INDEX IF NOT EXISTS idx_device_identifiers_type_value
    ON device_identifiers(identifier_type, identifier_value);

CREATE INDEX IF NOT EXISTS idx_files_sha256
    ON files(sha256);

CREATE INDEX IF NOT EXISTS idx_files_status
    ON files(status);

CREATE INDEX IF NOT EXISTS idx_files_storage_state
    ON files(storage_state);

CREATE INDEX IF NOT EXISTS idx_sources_device
    ON file_sources(device_id);

CREATE INDEX IF NOT EXISTS idx_restore_device
    ON restore_preferences(device_id);

CREATE INDEX IF NOT EXISTS idx_deletions_device
    ON deletion_events(device_id);

CREATE INDEX IF NOT EXISTS idx_manifest_status
    ON copy_manifest(status);

CREATE INDEX IF NOT EXISTS idx_manifest_file
    ON copy_manifest(file_id);

CREATE INDEX IF NOT EXISTS idx_folders_parent
    ON folders(parent_path);

CREATE INDEX IF NOT EXISTS idx_canonical_plan_status
    ON canonical_plan(review_status);

CREATE INDEX IF NOT EXISTS idx_canonical_plan_proposed
    ON canonical_plan(proposed_canonical_path);
