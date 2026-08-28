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
- be suitable as a professional portfolio project demonstrating SQL, Python, data modeling, data quality, automation, Linux and Git practices.

Initial devices:

- `PC`
- `TABLET`
- `PHONE1_A73`

The architecture must support any number of future devices without requiring device-specific code.

---

# 2. Non-Negotiable Engineering Principles

These are project-wide rules and do not need to be repeated in individual prompts.

### Device independent

No operational Python script should contain logic specific to:

- PC
- TABLET
- PHONE1_A73

Device identity must be supplied through a parameter such as:

```bash
--device PC
--device TABLET
--device PHONE1_A73
```

Adding a new device should require catalog registration and configuration/data, not code changes.

### Re-runnable / idempotent

Every operational script must be safe to run again.

A second execution should:

- detect already completed work;
- avoid duplicate database rows;
- avoid unnecessary file copies/moves;
- verify existing physical objects rather than blindly replacing them;
- produce a deterministic result.

### Dry-run first

Any script capable of changing files or database state must support:

```text
DRY RUN
    ↓
validation
    ↓
explicit EXECUTE
```

No destructive or physical operation should occur implicitly.

### SHA-256 is the identity

Filename and path are metadata.

SHA-256 is the authoritative content identity.

Never determine file identity solely from:

- filename;
- extension;
- source path;
- file size.

### Provenance is retained

A logical file may have multiple source occurrences.

Therefore:

```text
files
    = logical/master object

file_sources
    = source-device provenance
```

Multiple source occurrences must not automatically create multiple logical `files` records.

### Canonical path is authoritative for restoration

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

If the user renamed/reorganized a file in MASTER, the current canonical MASTER organization prevails during restoration.

### `_Bin` is quarantine, not restore source

Files in:

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

---

# 3. Current Target Architecture

## Active catalog

```text
devices
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

# 4. Phase 0 — Repository Engineering Cleanup

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
- [ ] Define a clean source-code structure.
- [ ] Create a single project README.
- [ ] Create architecture documentation.
- [ ] Create data-model documentation.
- [ ] Establish coding conventions.
- [ ] Establish CLI conventions.
- [ ] Establish logging conventions.
- [ ] Establish dry-run/execute conventions.
- [ ] Establish error-handling conventions.
- [ ] Establish idempotency expectations.
- [ ] Add automated tests.

### Portfolio objective

A recruiter should see:

```text
src/
tests/
sql/
docs/
examples/
archive/
```

rather than a chronological collection of migration scripts.

---

# 5. Phase 1 — Catalog Foundation

### Goal

Make SQLite the authoritative metadata/catalog layer.

### Tasks

- [x] `devices`
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

- [ ] Document and freeze the schema.
- [ ] Add indexes where query patterns justify them.
- [ ] Add catalog validation tests.
- [ ] Document FK relationships.
- [ ] Document lifecycle states.

---

# 6. Phase 2 — Device Ingestion

### Goal

Create a reusable ingestion pipeline.

```text
DEVICE
   ↓
inventory
   ↓
SHA-256
   ↓
catalog registration
   ↓
file_sources
```

### Requirements

- [ ] Generic device inventory.
- [ ] Device passed as CLI parameter.
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

# 7. Phase 3 — Canonical Organization

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
- [ ] Retain `canonical_plan` as historical decision evidence.
- [ ] Define future canonical editing workflow.
- [ ] Add canonical collision validation.
- [ ] Add canonical-path safety validation.
- [ ] Add canonical rename/move validation.

---

# 8. Phase 4 — MASTER Storage

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
- [ ] Distinguish:
  - VALID_PATH
  - STALE_PATH
  - PHYSICALLY_MISSING
  - SIZE_MISMATCH
  - SHA_MISMATCH
- [ ] Add optional full SHA audit.
- [ ] Add fast path/size audit.
- [ ] Produce CSV audit reports.

---

# 9. Phase 5 — Duplicate Management

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
- [ ] Never delete catalog provenance when deleting physical duplicates.
- [ ] Add reversible recovery procedure.

---

# 10. Phase 6 — Device Restore

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

### Restore membership

```text
file_sources.device_id
```

### `_Bin`

Excluded by default.

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
- [ ] Improve manifest source resolution.
- [ ] Add restore target collision detection.
- [ ] Define restore overwrite policy.
- [ ] Implement device-independent `restore_device.py`.
- [ ] Dry-run restore.
- [ ] Execute restore to isolated test directory.
- [ ] Verify destination SHA-256.
- [ ] Verify restored file counts.
- [ ] Verify restored directory structure.
- [ ] Generate restore execution log.
- [ ] Add restore tests.
- [ ] Document complete device-recovery procedure.

---

# 11. Phase 7 — Staging Cleanup

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

# 12. Phase 8 — Media Metadata

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

# 13. Phase 9 — Data Quality & Observability

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
- [ ] restore-manifest blocker.

### Output

Produce machine-readable reports plus concise console summaries.

---

# 14. Phase 10 — Testing

### Unit tests

- [ ] SHA hashing.
- [ ] Path resolution.
- [ ] Canonical-path validation.
- [ ] Duplicate identification.
- [ ] Manifest generation.
- [ ] Restore target calculation.

### Integration tests

- [ ] Import sample device.
- [ ] Register duplicate source.
- [ ] Register new file.
- [ ] Move duplicate to `_Bin`.
- [ ] Generate restore manifest.
- [ ] Restore sample device.
- [ ] Verify restored SHA.
- [ ] Re-run same operation and confirm idempotency.

### Negative tests

- [ ] Missing MASTER file.
- [ ] Wrong SHA.
- [ ] Wrong size.
- [ ] Canonical collision.
- [ ] Existing destination with different SHA.
- [ ] Invalid device ID.
- [ ] Invalid path escaping MASTER.
- [ ] IN_BIN file.
- [ ] Duplicate source path.
- [ ] Interrupted operation.

---

# 15. Phase 11 — Portfolio Engineering

### Goal

Make the project interview-ready.

### Documentation

- [ ] Professional README.
- [ ] Architecture diagram.
- [ ] ER/data-model diagram.
- [ ] End-to-end workflow diagram.
- [ ] Restore architecture documentation.
- [ ] Duplicate-cleanup documentation.
- [ ] Integrity-audit documentation.
- [ ] Design decisions / ADRs.
- [ ] Migration history.
- [ ] Example commands.
- [ ] Example reports.
- [ ] Synthetic/sample dataset.

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

# 16. Interview Story

The project should allow a concise explanation:

> I built a device-independent digital archive using Python and SQLite. Files are identified using SHA-256 rather than filenames, while source provenance is maintained separately from the logical master object. The system supports canonical organization, duplicate detection, reversible cleanup, physical integrity auditing, and device reconstruction. A device can be rebuilt from the current MASTER catalog, so the original folder structure is not required.

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
- CLI design
- reusable modules
- idempotent operations

### Engineering topics demonstrated

- requirements decomposition
- schema evolution
- migration strategy
- data quality
- auditability
- rollback
- dry-run workflows
- safe destructive operations
- provenance
- reproducibility
- testing
- Git-based development

---

# 17. Definition of Done

The project is considered portfolio-ready when:

```text
✓ PC supported
✓ TABLET supported
✓ PHONE1_A73 supported

✓ Additional devices require no code changes
✓ All operational scripts accept device/configuration parameters
✓ Operations are re-runnable
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
✓ Historical scripts are organized
✓ Repository contains no sensitive user data
✓ Project can be demonstrated end-to-end
```

---

# 18. Immediate Next Steps

1. **Repository inventory and cleanup**
2. **Retire the three empty temporary media workflow tables**
3. **Freeze the active catalog architecture**
4. **Inspect/adapt the existing restore mechanics only where useful**
5. **Finalize the restore manifest specification**
6. **Build device-independent restore executor**
7. **Run isolated TABLET restore test**
8. **Run PC and PHONE1_A73 restore tests**
9. **Build PC + TABLET + PHONE1_A73 staging cleanup dry-run**
10. **Begin portfolio documentation and tests**

## Standing Project Rule

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
NO DEVICE-SPECIFIC CODE
NO DESTRUCTIVE ACTION WITHOUT EXPLICIT EXECUTE
```