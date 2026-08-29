#!/usr/bin/env python3
import argparse, csv, subprocess, sys
from pathlib import Path

MAIN_DEFAULT=Path.home()/"my_scripts/digital_archive/PHONE_A73_duplicates/PHONE_A73_duplicate_review_updt.csv"
ZERO_DEFAULT=Path.home()/"my_scripts/digital_archive/PHONE_A73_duplicates/PHONE_A73_zero_keep_groups.csv"
VALIDATOR_DEFAULT=Path.home()/"my_scripts/digital_archive/validate_phone_a73_duplicate_review.py"
OUTPUT_DEFAULT=Path.home()/"my_scripts/digital_archive/PHONE_A73_duplicates/PHONE_A73_duplicate_review_FINAL.csv"

def load(path):
    with path.open("r",encoding="utf-8",newline="") as f:
        return list(csv.DictReader(f))

def n(v): return (v or "").strip()

def main():
    ap=argparse.ArgumentParser(description="Merge finalized zero-KEEP decisions and rerun A73 duplicate validator.")
    ap.add_argument("--main",default=str(MAIN_DEFAULT))
    ap.add_argument("--zero",default=str(ZERO_DEFAULT))
    ap.add_argument("--validator",default=str(VALIDATOR_DEFAULT))
    ap.add_argument("--output",default=str(OUTPUT_DEFAULT))
    a=ap.parse_args()

    main_path=Path(a.main).expanduser().resolve()
    zero_path=Path(a.zero).expanduser().resolve()
    validator=Path(a.validator).expanduser().resolve()
    output=Path(a.output).expanduser().resolve()

    for x in (main_path,zero_path,validator):
        if not x.is_file(): raise SystemExit(f"ERROR: file not found: {x}")

    main_rows=load(main_path)
    zero_rows=load(zero_path)
    if not main_rows or not zero_rows: raise SystemExit("ERROR: input CSV is empty.")

    main_fields=list(main_rows[0].keys())
    zfields=set(zero_rows[0].keys())
    for col in ("sha256","relative_path"):
        if col not in main_fields or col not in zfields:
            raise SystemExit(f"ERROR: missing key column: {col}")

    override=[x for x in ("keep_decision","manual_filename","manual_canonical_path") if x in main_fields and x in zfields]

    def index(rows):
        d={}
        for i,r in enumerate(rows):
            key=(n(r["sha256"]).lower(),n(r["relative_path"]))
            if key in d: raise SystemExit(f"ERROR: duplicate key in CSV: {key}")
            d[key]=i
        return d

    mi=index(main_rows); zi=index(zero_rows)
    missing=[k for k in zi if k not in mi]
    if missing:
        print("ERROR: zero-KEEP rows missing from main review:")
        for k in missing[:100]: print(f"  {k[0]} | {k[1]}")
        raise SystemExit(2)

    for key,zidx in zi.items():
        if "keep_decision" in zfields and not n(zero_rows[zidx]["keep_decision"]):
            raise SystemExit(f"ERROR: blank keep_decision in zero-KEEP file: {key}")
        midx=mi[key]
        for col in override:
            main_rows[midx][col]=zero_rows[zidx][col]

    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open("w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,fieldnames=main_fields); w.writeheader(); w.writerows(main_rows)

    with output.open("r",encoding="utf-8",newline="") as f:
        final_rows=list(csv.DictReader(f))

    print("="*78)
    print("PHONE A73 DUPLICATE REVIEW MERGE")
    print("="*78)
    print("Main input rows :",len(main_rows))
    print("Zero-KEEP rows  :",len(zero_rows))
    print("Rows updated    :",len(zero_rows))
    print("Final output    :",output)
    print("Final row count :",len(final_rows))
    print("Override fields :",", ".join(override))
    if len(final_rows)!=len(main_rows): raise SystemExit("ERROR: row count changed.")

    print("\nRunning validator...")
    rc=subprocess.run([sys.executable,str(validator),str(output)]).returncode
    print("\nFINAL VALIDATION:", "PASS" if rc==0 else "FAIL")
    if rc: raise SystemExit(rc)

if __name__=="__main__": main()
