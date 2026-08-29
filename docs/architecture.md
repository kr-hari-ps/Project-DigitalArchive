# Architecture

Digital Archive is structured as a reusable Python application over a SQLite catalog and a physical MASTER repository.

```text
Desktop UI / CLI
       |
Application services
       |
Catalog repositories + filesystem services
       |
SQLite catalog ---- MASTER filesystem
```

## Layer rules

- UI contains presentation and workflow orchestration only.
- Application services contain business rules.
- Catalog modules own SQL access.
- Filesystem modules own physical file operations.
- CLI and GUI should consume the same service layer.
- Device-specific behavior belongs in discovery adapters, not core business logic.

## Core identity model

- `devices.device_id`: stable application identifier.
- `devices.device_uuid`: immutable Digital Archive identity.
- `device_identifiers`: external identifiers discovered from devices.
- `files.file_id`: logical file object.
- `files.sha256`: authoritative file-content identity.
- `file_sources`: source-device provenance.

## Restore model

Device membership comes from `file_sources`; restore source comes from the active MASTER object; restore destination comes from `files.canonical_path`; `_Bin` is excluded by default.
