# Digital Archive

A device-independent, SHA-256-based digital archive and recovery system built with Python and SQLite.

## Project goal

The system manages files collected from multiple devices, preserves source provenance, maintains a canonical MASTER repository, detects exact duplicates, validates physical/catalog integrity, and reconstructs a device using the current MASTER organization.

Initial devices:

- `PC`
- `TABLET`
- `PHONE1_A73`

The design is device-independent and intended to support additional devices without changing core business logic.

## Architecture

```text
Desktop UI / CLI
       |
Application services
       |
Catalog repositories + filesystem services
       |
SQLite catalog ---- MASTER repository
```

Core rules:

- SHA-256 is the authoritative file identity.
- `file_sources` preserves device/source provenance.
- `files.canonical_path` is authoritative for current organization and restore destination.
- `files.master_path` identifies the physical MASTER source.
- `IN_BIN` files are excluded from normal restoration.
- CLI and GUI consume the same reusable service layer.
- Mutating workflows are dry-run first and designed to be re-runnable.

## Repository structure

```text
src/digital_archive/     reusable application code
tests/                   unit and integration tests
sql/                     schema, migrations, verification
docs/                    architecture and design documentation
examples/                synthetic/sample inputs
archive/                 historical and superseded migration material
```

## Application

The desktop UI is being built with PySide6. Device management is the first vertical slice: discover a connected device, match or register its identity, and populate the catalog through reusable backend services.

## Current capabilities

- multi-device ingestion and provenance
- SHA-256 identity and verification
- canonical path management
- duplicate grouping and reversible cleanup to `_Bin`
- physical/catalog integrity auditing
- device restore manifest generation
- device-independent restore design
- media metadata model for future photo/music/video enrichment

## Development principles

See `Digital Archive — Project Baseline & Master To-Do List.md` for the standing project specification.
