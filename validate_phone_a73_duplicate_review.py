#!/usr/bin/env python3
#---------------------------------------------------------------------
# 1. keep_decision validation
# 2. SHA-group validation
#       → exactly 1 KEEP per duplicate SHA group
# 3. KEEP proposal validation
#       → filename present
#       → manual_canonical_path present
#       → path ends with filename
# 4. Full canonical-path collision check
# 5. Absolute-path check
# 6. Generates KEEP / REMOVE / THUMBNAILS CSV subsets
# 7. Generates a validation summary
#---------------------------------------------------------------------
# python3 ~/my_scripts/digital_archive/validate_phone_a73_duplicate_review.py ~/my_scripts/digital_archive/PHONE_A73_duplicates/PHONE_A73_duplicate_review_updt.csv
#---------------------------------------------------------------------

import argparse, csv
from collections import Counter, defaultdict
from pathlib import Path

ALLOWED={"KEEP","REMOVE","THUMBNAILS","NO_RETAINED_COPIES"}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--output-dir")
    a=ap.parse_args()
    src=Path(a.csv).expanduser().resolve()
    if not src.is_file(): raise SystemExit(f"ERROR: not found: {src}")
    out=Path(a.output_dir).expanduser().resolve() if a.output_dir else src.parent/"PHONE_A73_duplicate_validation"
    out.mkdir(parents=True,exist_ok=True)
    with src.open("r",encoding="utf-8",newline="") as f: rows=list(csv.DictReader(f))
    if not rows: raise SystemExit("ERROR: no rows")
    required={"sha256","duplicate_group_size","folder_name","file_name","relative_path","size_bytes","keep_decision","filename","manual_canonical_path"}
    miss=required-set(rows[0])
    if miss: raise SystemExit(f"ERROR: missing columns: {sorted(miss)}")

    decisions=Counter(r["keep_decision"].strip().upper() for r in rows)
    invalid=[(i,r) for i,r in enumerate(rows,2) if r["keep_decision"].strip().upper() not in ALLOWED]

    groups=defaultdict(list)
    for r in rows: groups[r["sha256"].strip().lower()].append(r)
    zero=[]; multi=[]
    for sha,g in groups.items():
        k=sum(r["keep_decision"].strip().upper()=="KEEP" for r in g)
        if k==0: zero.append((sha,g))
        elif k>1: multi.append((sha,g))

    keep=[r for r in rows if r["keep_decision"].strip().upper()=="KEEP"]
    missing_props=[r for r in keep if not r["filename"].strip() or not r["manual_canonical_path"].strip()]
    inconsistent=[r for r in keep if r["manual_canonical_path"].strip() and r["filename"].strip() and not (
        r["manual_canonical_path"].strip()==r["filename"].strip() or
        r["manual_canonical_path"].strip().endswith("/"+r["filename"].strip())
    )]

    paths=defaultdict(list)
    for r in keep: paths[r["manual_canonical_path"].strip()].append(r)
    collisions={k:v for k,v in paths.items() if len(v)>1}
    absolute=[r for r in keep if r["manual_canonical_path"].strip().startswith("/")]

    fields=list(rows[0])

    def write(name,pred):
        data=[r for r in rows if pred(r)]
        with (out/name).open("w",encoding="utf-8",newline="") as f:
            w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(data)
        return len(data)

    counts={
        "KEEP":write("PHONE_A73_DUP_KEEP.csv",lambda r:r["keep_decision"].strip().upper()=="KEEP"),
        "REMOVE":write("PHONE_A73_DUP_REMOVE.csv",lambda r:r["keep_decision"].strip().upper()=="REMOVE"),
        "THUMBNAILS":write("PHONE_A73_DUP_THUMBNAILS.csv",lambda r:r["keep_decision"].strip().upper()=="THUMBNAILS"),
    }
    passed=not(invalid or zero or multi or missing_props or inconsistent or collisions or absolute)

    print("="*78); print("PHONE A73 UPDATED DUPLICATE REVIEW"); print("="*78)
    print("Rows :",len(rows)); print("SHA groups :",len(groups))
    for x in ("KEEP","REMOVE","THUMBNAILS",""): print(f"{x or '[BLANK]':12}: {decisions[x]}")
    print(); print("Groups with 0 KEEP :",len(zero))
    print("Groups with >1 KEEP:",len(multi))
    print("KEEP missing proposals :",len(missing_props))
    print("KEEP inconsistent paths :",len(inconsistent))
    print("Canonical path collisions:",len(collisions))
    print("Absolute paths:",len(absolute))
    print(); print("OUTPUTS")
    for k,v in counts.items(): print(f"{k:12}: {v}")
    print(); print("VALIDATION :", "PASS" if passed else "FAIL")
    print("Output directory:",out)

    with (out/"PHONE_A73_duplicate_validation_summary.csv").open("w",encoding="utf-8",newline="") as f:
        w=csv.writer(f); w.writerow(["metric","value"])
        vals=[("input_rows",len(rows)),("sha_groups",len(groups)),("keep_rows",counts["KEEP"]),("remove_rows",counts["REMOVE"]),("thumbnail_rows",counts["THUMBNAILS"]),("blank_rows",decisions[""]),("invalid_decisions",len(invalid)),("zero_keep_groups",len(zero)),("multi_keep_groups",len(multi)),("missing_proposals",len(missing_props)),("inconsistent_paths",len(inconsistent)),("path_collisions",len(collisions)),("absolute_paths",len(absolute)),("validation_pass",int(passed))]
        w.writerows(vals)
    if not passed:
        print("\nIssues:")
        for label,data in [("INVALID DECISIONS",invalid),("ZERO-KEEP GROUPS",zero),("MULTI-KEEP GROUPS",multi),("MISSING PROPOSALS",missing_props),("INCONSISTENT PATHS",inconsistent),("PATH COLLISIONS",collisions),("ABSOLUTE PATHS",absolute)]:
            if data: print(f"  {label}: {len(data)}")
        raise SystemExit(2)

if __name__=="__main__": main()
