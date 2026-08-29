# Canonical Path Planning

This is a **planning-only** stage.

It proposes the final logical path for each selected master file and stores the proposal in `canonical_plan`.

It does not:
- move files
- rename files
- delete files
- change `files.canonical_path`
- change the current staging master

## Current principles

Documents:
- preserve useful existing tablet `\`epsilon/Personal/...` hierarchy
- preserve useful PC `ITR/...` hierarchy under `Documents/Finance/ITR/`
- keep Quick Share/download-only items in `Documents/To-Review/`
- classify apparent development/project trees as `_Review-NonPersonal`
- use conservative `To-Review` for anything not confidently classified

The existing source paths remain in `file_sources`.

## Run

```bash
~/my_scripts/digital_archive/plan_canonical_paths.sh \
  "$HOME/Master-Repository/.archive/catalog.db"
```

Expected first-pass plan:

```text
~292 REVIEW rows
```

## Review

Use Beekeeper:

```sql
SELECT
    cp.plan_id,
    cp.file_id,
    cp.current_canonical_path,
    cp.proposed_canonical_path,
    cp.proposal_rule,
    cp.proposal_reason,
    cp.review_status,
    f.filename,
    f.sha256
FROM canonical_plan cp
JOIN files f ON f.file_id=cp.file_id
ORDER BY cp.proposed_canonical_path;
```

Do not apply the proposals until they have been reviewed.

## Important

The plan deliberately separates:
- source provenance
- current staging physical path
- proposed canonical logical path

The later apply step will update `files.canonical_path` and physically move/copy files only after approval.
