# Data Model

## Device

`devices` stores the stable catalog identity and descriptive profile of each device.

`device_identifiers` stores one or more externally observed identifiers such as ADB serials, SMBIOS UUIDs, USB serials, filesystem UUIDs, or manually supplied identifiers.

## Files and provenance

```text
files
  |
  +-- file_sources
  +-- restore_preferences
  +-- duplicate_groups / duplicate_members
  +-- copy_manifest
  +-- deletion_events
  +-- file_xattrs
```

`files` is the logical/master object. `file_sources` records where that object was observed on a device.

## Restore

```text
device_id
  -> file_sources
  -> DISTINCT file_id
  -> files
  -> IN_MASTER
  -> master_path
  -> canonical_path
```

The source device's historical directory structure is provenance only and is not recreated during restore.
