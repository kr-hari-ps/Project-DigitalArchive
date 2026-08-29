# Manual Canonical Classification

The `canonical_plan` table now supports:

```text
manual_canonical_path
manual_category
manual_notes
```

These fields allow manual classification without changing source files or the staging master.

## Example

A source such as:

```text
Tablet-Original/Download/EAadhaar_....pdf
```

can be assigned manually to:

```text
Documents/Personal/Identity_n_Accounts/Aadhar/EAadhaar_....pdf
```

using:

```sql
UPDATE canonical_plan
SET
    manual_canonical_path =
        'Documents/Personal/Identity_n_Accounts/Aadhar/EAadhaar_....pdf',
    manual_category = 'Aadhar',
    manual_notes =
        'Identity document from tablet Download'
WHERE plan_id = 123;
```

## Rule

The later physical apply stage will use:

```text
manual_canonical_path
    if populated
        otherwise
proposed_canonical_path
```

Manual classification does not itself approve or move anything.

## Review states

```text
REVIEW
APPROVED
REJECTED
APPLIED
```

The original source path remains in `file_sources`.

The staging physical copy remains unchanged until a separate apply step is explicitly run.
