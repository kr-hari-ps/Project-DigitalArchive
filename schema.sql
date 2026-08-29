PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS devices(
    device_id TEXT PRIMARY KEY,
    device_uuid TEXT NOT NULL UNIQUE,
    device_name TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL,
    manufacturer TEXT,
    model TEXT,
    os_name TEXT,
    os_version TEXT,
    description TEXT,
    active INTEGER NOT NULL DEFAULT 1 CHECK(active IN(0,1)),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS device_identifiers(
    identifier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT NOT NULL,
    identifier_type TEXT NOT NULL,
    identifier_value TEXT NOT NULL,
    is_primary INTEGER NOT NULL DEFAULT 0 CHECK(is_primary IN(0,1)),
    first_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TEXT,
    notes TEXT,
    UNIQUE(identifier_type, identifier_value),
    FOREIGN KEY(device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_device_identifiers_device ON device_identifiers(device_id);
CREATE INDEX IF NOT EXISTS idx_device_identifiers_type_value ON device_identifiers(identifier_type, identifier_value);
CREATE TABLE IF NOT EXISTS files(file_id INTEGER PRIMARY KEY AUTOINCREMENT,sha256 TEXT NOT NULL,master_path TEXT,filename TEXT NOT NULL,extension TEXT,size_bytes INTEGER NOT NULL,media_type TEXT,capture_date TEXT,created_date TEXT,modified_date TEXT,status TEXT NOT NULL DEFAULT 'CATALOGED',notes TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE(sha256,master_path));
CREATE TABLE IF NOT EXISTS file_sources(file_id INTEGER NOT NULL,device_id TEXT NOT NULL,source_path TEXT,source_filename TEXT,source_size_bytes INTEGER,source_sha256 TEXT NOT NULL,source_modified_date TEXT,first_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(file_id,device_id,source_path),FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE,FOREIGN KEY(device_id) REFERENCES devices(device_id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS restore_preferences(file_id INTEGER NOT NULL,device_id TEXT NOT NULL,restore_enabled INTEGER NOT NULL DEFAULT 1 CHECK(restore_enabled IN(0,1)),target_relative_path TEXT,notes TEXT,PRIMARY KEY(file_id,device_id),FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE,FOREIGN KEY(device_id) REFERENCES devices(device_id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS duplicate_groups(duplicate_group_id TEXT PRIMARY KEY,sha256 TEXT NOT NULL,decision TEXT NOT NULL DEFAULT 'REVIEW' CHECK(decision IN('REVIEW','KEEP_ONE','KEEP_ALL','IGNORE')),chosen_file_id INTEGER,notes TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,FOREIGN KEY(chosen_file_id) REFERENCES files(file_id));
CREATE TABLE IF NOT EXISTS duplicate_members(duplicate_group_id TEXT NOT NULL,file_id INTEGER NOT NULL,PRIMARY KEY(duplicate_group_id,file_id),FOREIGN KEY(duplicate_group_id) REFERENCES duplicate_groups(duplicate_group_id) ON DELETE CASCADE,FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE);
CREATE TABLE IF NOT EXISTS folders(folder_id INTEGER PRIMARY KEY AUTOINCREMENT,master_path TEXT NOT NULL UNIQUE,folder_name TEXT NOT NULL,parent_path TEXT,folder_type TEXT,description TEXT,device_summary TEXT,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS copy_manifest(manifest_id INTEGER PRIMARY KEY AUTOINCREMENT,file_id INTEGER NOT NULL,source_device_id TEXT NOT NULL,destination_path TEXT NOT NULL,source_path TEXT NOT NULL,source_sha256 TEXT NOT NULL,destination_sha256 TEXT,source_size_bytes INTEGER,destination_size_bytes INTEGER,copied_at TEXT,verified_at TEXT,status TEXT NOT NULL DEFAULT 'PLANNED' CHECK(status IN('PLANNED','COPIED','VERIFIED','FAILED','SKIPPED')),verification_method TEXT,error_message TEXT,notes TEXT,FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE,FOREIGN KEY(source_device_id) REFERENCES devices(device_id));
CREATE TABLE IF NOT EXISTS deletion_events(deletion_id INTEGER PRIMARY KEY AUTOINCREMENT,file_id INTEGER,device_id TEXT NOT NULL,original_path TEXT,deleted_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,bin_path TEXT,reason TEXT,sha256 TEXT,notes TEXT,FOREIGN KEY(file_id) REFERENCES files(file_id),FOREIGN KEY(device_id) REFERENCES devices(device_id));
CREATE TABLE IF NOT EXISTS file_xattrs(file_id INTEGER PRIMARY KEY,xattr_supported INTEGER NOT NULL DEFAULT 0 CHECK(xattr_supported IN(0,1)),xattr_applied INTEGER NOT NULL DEFAULT 0 CHECK(xattr_applied IN(0,1)),xattr_names TEXT,last_checked_at TEXT,FOREIGN KEY(file_id) REFERENCES files(file_id) ON DELETE CASCADE);
CREATE INDEX IF NOT EXISTS idx_files_sha256 ON files(sha256);
CREATE INDEX IF NOT EXISTS idx_sources_device ON file_sources(device_id);
CREATE INDEX IF NOT EXISTS idx_manifest_status ON copy_manifest(status);
CREATE INDEX IF NOT EXISTS idx_manifest_file ON copy_manifest(file_id);
CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(parent_path);
