# Digital Archive — Project Baseline & Master To-Do List

## 1. Project Vision

Build a reusable, SHA-256-based digital archive and device-recovery system using Python + SQLite.

The system should:

- ingest files from multiple devices;
- preserve source provenance;
- identify logical files using SHA-256;
- maintain a canonical MASTER repository;
- detect and manage exact duplicates safely;
- maintain physical and catalog integrity;
- support future media metadata enrichment;
- reconstruct a device from the current MASTER catalog;
- provide a reusable Python desktop application with a GUI;
- keep UI, application services, database access, and physical file operations separated;
- be suitable as a professional portfolio project demonstrating SQL, Python, data modeling, data quality, automation, Linux, Git and desktop application architecture.

Initial devices:

- `PC`
- `TABLET`
- `PHONE1_A73`

The architecture must support any number of future devices without requiring device-specific code.

---

# 2. Non-Negotiable Engineering Principles

These are project-wide rules and do not need to be repeated in individual prompts.

### Device independent

No operational Python code should contain logic specific to:

- PC
- TABLET
- PHONE1_A73

Device identity must be supplied through configuration, catalog data, discovery adapters, or parameters such as:

```bash
--device PC
--device TABLET
--device PHONE1_A73
```

Adding a new device should require catalog registration and/or a discovery adapter, not changes to core business logic.

### Re-runnable / idempotent

Every operational workflow must be safe to run again.

A second execution should:

- detect already completed work;
- avoid duplicate database rows;
- avoid unnecessary file copies/moves;
- verify existing physical objects rather than blindly replacing them;
- preserve immutable device and file identities;
- produce a deterministic result.

### Dry-run first

Any operation capable of changing files or database state must support:

```text
DRY RUN
    ↓
validation
    ↓
explicit EXECUTE
```

No destructive or physical operation should occur implicitly.

### SHA-256 is the file identity

Filename and path are metadata.

SHA-256 is the authoritative content identity for files.

Never determine logical file identity solely from:

- filename;
- extension;
- source path;
- file size.

### Device identity

`devices.device_uuid` is the immutable archive identity for a device record.

`devices.device_id` is the human/application identifier and must remain stable unless an explicit administrative rename is performed.

External identifiers are stored separately in `device_identifiers` and may include platform-specific values such as:

- `ADB_SERIAL`
- `SMBIOS_UUID`
- `SYSTEM_SERIAL`
- `USB_SERIAL`
- `FILESYSTEM_UUID`
- `MTP_ID`
- `HOST_MACHINE_ID`
- `MANUAL`

External identifiers are evidence for recognizing a connected device; they are not the archive's primary identity.

A device may have multiple external identifiers.

An external identifier value must not be silently assigned to multiple devices.

### Provenance is retained

A logical file may have multiple source occurrences.

Therefore:

```text
files
    = logical/master object

file_sources
    = device/source provenance
```

Multiple source occurrences must not automatically create multiple logical `files` records.

### Canonical path is authoritative for organization and restoration

For device reconstruction:

```text
file_sources
    → determines device membership

files.canonical_path
    → determines restored path + filename

files.master_path
    → identifies physical MASTER source

files.sha256
    → verifies object identity
```

The original source directory tree must NOT be recreated.

If a file was renamed or reorganized in MASTER, the current canonical MASTER organization prevails during restoration.

### `_Bin` is quarantine, not restore source

Files with:

```text
storage_state = IN_BIN
```

are excluded from normal device restoration.

They represent cleanup/quarantine state, not active device content.

### Separate logical, physical and provenance concepts

Never collapse:

```text
source_path
master_path
canonical_path
```

They have different meanings.

### UI is not the business logic

The desktop UI must not contain raw SQL, file-copy logic, duplicate-cleanup logic, or catalog business rules.

The UI calls reusable application services.

CLI and GUI must consume the same service layer wherever practical.

---

# 3. Current Target Architecture

## Active catalog

```text
devices
device_identifiers
files
file_sources
restore_preferences
duplicate_groups
duplicate_members
deletion_events
file_xattrs
folders
copy_manifest
```

## Historical/review information

```text
canonical_plan
multi_media_assets
media_copy_manifest
```

## Future media enrichment

```text
media_metadata
```

## Temporary workflow tables already identified for retirement

```text
media_manual_review_import
media_canonical_move_manifest
media_physical_cleanup_manifest
```

These were empty at the time of review and are candidates for removal after the appropriate backup/checkpoint.

---

# 4. Repository Architecture

The repository is now organized by reusable capability rather than migration chronology.

Target structure:

```text
Project-DigitalArchive/
│
├── README.md
├── LICENSE
├── pyproject.toml
│
├── src/
│   └── digital_archive/
│       ├── __init__.py
│       ├── cli.py
│       │
│       ├── catalog/
│       ├── devices/
│       ├── ingestion/
│       ├── canonical/
│       ├── duplicates/
│       ├── integrity/
│       ├── restore/
│       ├── media/
│       └── ui/
│
├── sql/
│   ├── schema.sql
│   ├── migrations/
│   └── verification/
│
├── tests/
│   ├── unit/
│   └── integration/
│
├── docs/
│   ├── architecture.md
│   ├── data-model.md
│   ├── restore-design.md
│   ├── device-identity.md
│   ├── migration-history.md
│   └── runbooks/
│
├── examples/
│
└── archive/
    ├── phase1/
    ├── historical-scripts/
    └── superseded/
```

### Structure rules

- Reusable production logic belongs under `src/digital_archive/`.
- Database schema and migrations belong under `sql/`.
- Automated tests belong under `tests/`.
- Design and operational documentation belongs under `docs/`.
- Synthetic examples belong under `examples/`.
- Superseded scripts and historical evidence belong under `archive/`.
- Personal data, production catalog databases, credentials, and private source paths must not be committed.
- Historical scripts should be archived rather than silently deleted until their useful behavior has been reviewed.

---

# 5. Application Architecture

The desktop application is a product layer over reusable services.

```text
                    Desktop UI
                         │
                 Application Services
                         │
       ┌─────────────────┼──────────────────┐
       │                 │                  │
    Catalog           Device            Restore
    Service           Service            Service
       │                 │                  │
       └─────────────────┼──────────────────┘
                         │
                  Repository / DB
                         │
                       SQLite
                         │
                Physical MASTER / Devices
```

### UI technology

Use a Python desktop framework such as PySide6/Qt unless a later architecture review identifies a better option.

### Initial UI capability

Start with:

```text
Connect / Select Device
        ↓
Device discovery
        ↓
External identifier detection
        ↓
Match existing device or request registration
        ↓
Populate/update devices + device_identifiers
```

The UI should present a device without requiring device-specific code.

### Future UI menu areas

```text
File
Devices
Ingestion
Canonical
Duplicates
Integrity
Restore
Media
Reports
Help
```

The UI should call application services and should not reimplement business logic.

---

# 6. Phase 0 — Repository Engineering Cleanup

### Goal

Turn the accumulated migration scripts into a clean portfolio-quality project.

### Tasks

- [ ] Inventory every script in the repository.
- [ ] Identify current/reusable implementations.
- [ ] Identify superseded versions.
- [ ] Identify one-off/debug/session-specific scripts.
- [ ] Identify historical evidence and run artifacts.
- [ ] Move historical scripts into an archive area.
- [ ] Keep historical runbooks and results where useful.
- [ ] Avoid deleting historical evidence prematurely.
- [x] Define clean source-code structure.
- [ ] Create/refresh the single project README.
- [ ] Create architecture documentation.
- [ ] Create data-model documentation.
- [ ] Establish coding conventions.
- [ ] Establish CLI conventions.
- [ ] Establish logging conventions.
- [ ] Establish dry-run/execute conventions.
- [ ] Establish error-handling conventions.
- [ ] Establish idempotency expectations.
- [ ] Add automated tests.
- [ ] Define packaging/application entry points.

---

# 7. Phase 1 — Catalog Foundation

### Goal

Make SQLite the authoritative metadata/catalog layer.

### Tasks

- [x] `devices`
- [x] `device_identifiers` schema defined
- [x] `files`
- [x] `file_sources`
- [x] `folders`
- [x] `copy_manifest`
- [x] `duplicate_groups`
- [x] `duplicate_members`
- [x] `deletion_events`
- [x] `restore_preferences`
- [x] storage-state model
- [x] canonical-path model
- [x] SHA-256 identity
- [x] PC registration
- [x] TABLET registration
- [x] PHONE1_A73 registration

### Remaining

- [ ] Apply and validate device identity migration on the active catalog.
- [ ] Populate external identifiers for existing devices where available.
- [ ] Freeze the active production schema.
- [ ] Add indexes where query patterns justify them.
- [ ] Add catalog validation tests.
- [ ] Document FK relationships.
- [ ] Document lifecycle states.

---

# 8. Phase 2 — Device Discovery & Ingestion

### Goal

Create a reusable device discovery and ingestion pipeline.

```text
CONNECTED DEVICE
      ↓
DISCOVERY ADAPTER
      ↓
DEVICE IDENTITY
      ↓
INVENTORY
      ↓
SHA-256
      ↓
CATALOG REGISTRATION
      ↓
file_sources
```

### Requirements

- [ ] Generic device discovery interface.
- [ ] Android/ADB discovery adapter.
- [ ] PC discovery adapter(s).
- [ ] Generic/manual discovery fallback.
- [ ] Discover and record external identifiers.
- [ ] Match a connected device against registered identifiers.
- [ ] Require confirmation when identity is ambiguous.
- [ ] Device passed as a parameter where appropriate.
- [ ] Source paths preserved exactly.
- [ ] Source filename preserved.
- [ ] Source size recorded.
- [ ] SHA-256 recorded.
- [ ] File timestamps recorded where available.
- [ ] Extension/media type derived consistently.
- [ ] Existing SHA recognized.
- [ ] Existing logical file reused.
- [ ] New logical file inserted only when necessary.
- [ ] Existing source occurrence detected before inserting.
- [ ] Re-run produces no duplicate source rows.

---

# 9. Phase 3 — Canonical Organization

### Goal

Separate automated suggestions from human-approved organization.

### Design

```text
source structure
      ↓
proposal
      ↓
human decision
      ↓
files.canonical_path
```

### Tasks

- [x] Historical canonical planning completed for 292 documents.
- [x] Manual canonical decisions applied.
- [x] Canonical paths verified against MASTER.
- [ ] Stop using `canonical_plan` operationally.
- [x] Retain `canonical_plan` as historical decision evidence.
- [ ] Define future canonical editing workflow.
- [ ] Add canonical collision validation.
- [ ] Add canonical-path safety validation.
- [ ] Add canonical rename/move validation.

---

# 10. Phase 4 — MASTER Storage

### Goal

Maintain a verified physical MASTER repository.

### Tasks

- [x] MASTER root established.
- [x] Physical copies SHA-verified.
- [x] A73 physical copy completed.
- [x] Copy manifest recorded.
- [x] Canonical paths verified.
- [x] Stale path case identified and repaired.
- [ ] Generalize physical-path resolver.
- [ ] Build reusable physical integrity audit.
- [x] Distinguish:
  - VALID_PATH
  - STALE_PATH
  - PHYSICALLY_MISSING
  - SIZE_MISMATCH
  - SHA_MISMATCH
- [ ] Add optional full SHA audit.
- [x] Add fast path/size audit.
- [x] Produce CSV audit reports.

---

# 11. Phase 5 — Duplicate Management

### Goal

Safely remove redundant source copies without losing provenance.

### Principle

```text
exact SHA duplicate
        ↓
retain one logical/master object
        ↓
preserve all file_sources
        ↓
move redundant physical source to _Bin
```

### Tasks

- [x] Exact duplicate groups.
- [x] KEEP_ONE model.
- [x] `_Bin` cleanup.
- [x] deletion_events.
- [x] SHA verification of `_Bin` copies.
- [x] storage_state = IN_BIN.
- [ ] Generalize duplicate analysis to all devices.
- [ ] Build staging duplicate dry-run.
- [ ] Include MASTER verification.
- [ ] Include provenance checks.
- [x] Never delete catalog provenance when deleting physical duplicates.
- [ ] Add reversible recovery procedure.

---

# 12. Phase 6 — Device Restore

## Objective

Reconstruct a device from the current MASTER catalog.

Example:

```text
Format TABLET
     ↓
new TABLET storage
     ↓
restore --device TABLET
     ↓
current MASTER organization
```

### Restore selection

The restore set MUST be derived through `file_sources`:

```text
requested device
      ↓
file_sources.device_id
      ↓
DISTINCT file_id
      ↓
files
```

### Restore source

Only active MASTER objects:

```text
files.storage_state = IN_MASTER
```

### Restore destination

```text
files.canonical_path
```

### Restore identity

```text
files.sha256
```

### `_Bin`

Excluded by default and never treated as an implicit restore source.

### Current status

- [x] Defined restore model.
- [x] Created device-independent restore-manifest builder.
- [x] TABLET manifest generated.
- [x] PC manifest generated.
- [x] PHONE1_A73 manifest generated.
- [x] Canonical path verification completed.
- [x] PC stale-path issue resolved.
- [x] A73 stale-path issue resolved.
- [x] `IN_BIN` explicitly excluded.
- [x] Restore set uses `file_sources` device membership.

### Current restore readiness

```text
PC
    149 unique objects
    147 ready
      2 IN_BIN excluded
      0 blocked

TABLET
    737 unique objects
    722 ready
     15 IN_BIN excluded
      0 blocked

PHONE1_A73
    5440 unique objects
    5440 ready
       0 IN_BIN excluded
       0 blocked
```

### Remaining

- [ ] Freeze restore-manifest specification.
- [ ] Add device_uuid to restore manifest.
- [ ] Improve manifest source resolution.
- [ ] Add restore target collision detection.
- [ ] Define restore overwrite policy.
- [ ] Implement device-independent restore service/executor.
- [ ] Dry-run restore.
- [ ] Execute restore to isolated test directory.
- [ ] Verify destination SHA-256.
- [ ] Verify restored file counts.
- [ ] Verify restored directory structure.
- [ ] Generate restore execution log.
- [ ] Add restore tests.
- [ ] Document complete device-recovery procedure.

---

# 13. Phase 7 — Staging Cleanup

### Goal

Make staging disposable after MASTER and catalog become authoritative.

### Safety rule

A staging file becomes a cleanup candidate only when:

```text
SHA matches catalog
AND
MASTER object exists
AND
MASTER object is verified
AND
source provenance is known
AND
file is not itself the MASTER object
```

### Tasks

- [ ] Identify staging roots.
- [ ] Inventory PC staging.
- [ ] Inventory TABLET staging.
- [ ] Inventory PHONE1_A73 staging.
- [ ] Match staging files by SHA.
- [ ] Check source provenance.
- [ ] Verify MASTER physical object.
- [ ] Generate dry-run report.
- [ ] Review candidates.
- [ ] Move exact duplicates to `_Bin`.
- [ ] Verify moved SHA.
- [ ] Record deletion event.
- [ ] Update storage lifecycle where appropriate.
- [ ] Never permanently delete during first cleanup cycle.
- [ ] Re-run staging audit after cleanup.

---

# 14. Phase 8 — Media Metadata

### Goal

Build media intelligence after catalog consolidation.

`media_metadata` is intentionally retained.

Future metadata includes:

```text
MIME type
width
height
orientation
duration
bitrate
sample rate
codec
camera make
camera model
capture date
artist
album
title
metadata_json
```

### Future capabilities

- [ ] Extract EXIF metadata.
- [ ] Extract audio metadata.
- [ ] Extract video metadata.
- [ ] Associate media metadata with logical file objects.
- [ ] Design photo album queries.
- [ ] Design music grouping.
- [ ] Design video filtering.
- [ ] Build media reports.
- [ ] Consider migrating media metadata association from `inventory_id` to `file_id` after the current migration is stable.

---

# 15. Phase 9 — Data Quality & Observability

### Goal

Make the system measurable and auditable.

### Checks

- [ ] Missing SHA.
- [ ] Duplicate SHA identity.
- [ ] Duplicate source paths.
- [ ] Orphan file_sources.
- [ ] Orphan duplicate members.
- [ ] IN_BIN without deletion event.
- [ ] deletion-event SHA mismatch.
- [ ] MASTER path missing.
- [ ] canonical path missing.
- [ ] canonical collision.
- [ ] physical size mismatch.
- [ ] physical SHA mismatch.
- [ ] copy-manifest mismatch.
- [ ] device membership mismatch.
- [ ] device identifier collision.
- [ ] restore-manifest blocker.

### Output

Produce machine-readable reports plus concise console summaries.

---

# 16. Phase 10 — Testing

### Unit tests

- [ ] SHA hashing.
- [ ] Path resolution.
- [ ] Canonical-path validation.
- [ ] Duplicate identification.
- [ ] Device identity matching.
- [ ] Device identifier collision detection.
- [ ] Manifest generation.
- [ ] Restore target calculation.
- [ ] Re-run/idempotency behavior.

### Integration tests

- [ ] Import sample device.
- [ ] Register duplicate source.
- [ ] Register new file.
- [ ] Move duplicate to `_Bin`.
- [ ] Generate restore manifest.
- [ ] Restore sample device.
- [ ] Verify restored SHA.
- [ ] Re-run same operation and confirm idempotency.
- [ ] Connect/discover a test device through a discovery adapter.
- [ ] Register/reconcile external identifiers.

### Negative tests

- [ ] Missing MASTER file.
- [ ] Wrong SHA.
- [ ] Wrong size.
- [ ] Canonical collision.
- [ ] Existing destination with different SHA.
- [ ] Invalid device ID.
- [ ] Invalid device identity.
- [ ] Invalid path escaping MASTER.
- [ ] IN_BIN file.
- [ ] Duplicate source path.
- [ ] Duplicate external identifier.
- [ ] Ambiguous device match.
- [ ] Interrupted operation.

---

# 17. Phase 11 — Desktop Application

### Goal

Provide a proper desktop UI over the reusable application services.

### Initial milestone — Device Manager

- [ ] Build application shell.
- [ ] Add menu structure.
- [ ] Add device list view.
- [ ] Add Connect/Discover Device action.
- [ ] Detect available device type.
- [ ] Collect external identifiers.
- [ ] Match existing device.
- [ ] Register new device when required.
- [ ] Generate immutable `device_uuid` once.
- [ ] Persist identifiers in `device_identifiers`.
- [ ] Show identity confidence/ambiguity.
- [ ] Never hide registration failures.

### Later UI milestones

- [ ] Inventory/import screen.
- [ ] Catalog browser.
- [ ] Canonical path review.
- [ ] Duplicate analysis and cleanup.
- [ ] Integrity dashboard.
- [ ] Restore wizard.
- [ ] Media metadata browser.
- [ ] Reports viewer.
- [ ] Operation history/log viewer.

### UI safety

Every mutating operation should expose:

```text
Preview / Dry Run
        ↓
Validation
        ↓
Explicit Execute
```

Long-running work should run outside the UI thread and report progress/errors without freezing the application.

---

# 18. Phase 12 — Portfolio Engineering

### Goal

Make the project interview-ready.

### Documentation

- [ ] Professional README.
- [ ] Architecture diagram.
- [ ] ER/data-model diagram.
- [ ] End-to-end workflow diagram.
- [ ] Device identity documentation.
- [ ] Restore architecture documentation.
- [ ] Duplicate-cleanup documentation.
- [ ] Integrity-audit documentation.
- [ ] Design decisions / ADRs.
- [ ] Migration history.
- [ ] Example commands.
- [ ] Example reports.
- [ ] Synthetic/sample dataset.
- [ ] Desktop UI screenshots/demo.

### Repository hygiene

- [ ] Remove sensitive/personal data.
- [ ] Remove actual catalog DB from public repository.
- [ ] Remove personal absolute paths where necessary.
- [ ] Keep anonymized examples.
- [ ] Archive historical implementation rather than deleting useful history.
- [ ] Mark superseded implementations clearly.

### Demonstration

Create one end-to-end demo:

```text
3 devices
   ↓
Discovery / registration
   ↓
ingestion
   ↓
SHA identity
   ↓
catalog
   ↓
canonicalization
   ↓
duplicate management
   ↓
integrity audit
   ↓
device restore
```

---

# 19. Interview Story

The project should allow a concise explanation:

> I built a device-independent digital archive using Python and SQLite. Files are identified using SHA-256 rather than filenames, while source provenance is maintained separately from the logical master object. The system supports canonical organization, duplicate detection, reversible cleanup, physical integrity auditing, and device reconstruction. A connected device can be identified through platform-specific external identifiers and mapped to an immutable archive identity. A device can then be rebuilt from the current MASTER catalog, so the original folder structure is not required.

### SQL topics demonstrated

- JOIN
- LEFT JOIN
- GROUP BY
- HAVING
- CASE
- EXISTS
- CTEs
- subqueries
- indexes
- foreign keys
- constraints
- transactions
- data reconciliation
- query-plan analysis
- window functions

### Python topics demonstrated

- pathlib
- argparse
- sqlite3
- hashlib
- CSV processing
- streaming file I/O
- error handling
- transaction management
- service-layer architecture
- desktop GUI development
- reusable modules
- idempotent operations

### Engineering topics demonstrated

- requirements decomposition
- schema evolution
- migration strategy
- heterogeneous device integration
- device identity management
- data quality
- auditability
- rollback
- dry-run workflows
- safe destructive operations
- provenance
- reproducibility
- testing
- Git
- desktop application architecture

---

# 20. Definition of Done

The project is considered portfolio-ready when:

```text
✓ PC supported
✓ TABLET supported
✓ PHONE1_A73 supported

✓ Additional devices require no core-code changes
✓ Device discovery is adapter-based
✓ Device identity is immutable
✓ External device identifiers are persisted
✓ All operational scripts/services are re-runnable
✓ Mutating operations have dry-run mode
✓ SHA-256 is authoritative
✓ Source provenance is preserved
✓ MASTER is authoritative
✓ canonical_path controls restore destination
✓ _Bin is excluded from normal restore
✓ Restore is verified by SHA-256
✓ Duplicate cleanup is reversible
✓ Integrity audits are automated
✓ Tests exist
✓ Documentation exists
✓ Desktop UI uses the same service layer as CLI
✓ Repository contains no sensitive user data
✓ Historical scripts are organized
✓ Project can be demonstrated end-to-end
```

# 21. Standing Project Rule

Unless explicitly overridden, all future Digital Archive work must follow:

```text
DEVICE-INDEPENDENT
RE-RUNNABLE
DRY-RUN FIRST
SHA-256 BASED
CATALOG-DRIVEN
PROVENANCE-PRESERVING
MASTER-AUTHORITATIVE
CANONICAL-PATH-AWARE
_BIN EXCLUDED FROM NORMAL RESTORE
NO DEVICE-SPECIFIC CORE LOGIC
NO DESTRUCTIVE ACTION WITHOUT EXPLICIT EXECUTE
UI SEPARATED FROM BUSINESS LOGIC
SINGLE REUSABLE SERVICE LAYER FOR CLI + GUI
IMMUTABLE DEVICE IDENTITY
EXTERNAL DEVICE IDENTIFIERS ARE SUPPORTING EVIDENCE
```
