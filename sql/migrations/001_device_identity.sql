PRAGMA foreign_keys=ON;

-- Additive migration. Existing device_id values remain unchanged.
ALTER TABLE devices ADD COLUMN device_uuid TEXT;
ALTER TABLE devices ADD COLUMN manufacturer TEXT;
ALTER TABLE devices ADD COLUMN model TEXT;
ALTER TABLE devices ADD COLUMN os_name TEXT;
ALTER TABLE devices ADD COLUMN os_version TEXT;
ALTER TABLE devices ADD COLUMN updated_at TEXT;

-- Existing rows must be assigned immutable UUIDs by the migration script,
-- not by a schema default, so the operation is explicit and auditable.
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_uuid ON devices(device_uuid);

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

CREATE INDEX IF NOT EXISTS idx_device_identifiers_device
    ON device_identifiers(device_id);
CREATE INDEX IF NOT EXISTS idx_device_identifiers_type_value
    ON device_identifiers(identifier_type, identifier_value);
