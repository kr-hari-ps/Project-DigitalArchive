#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

DIR1="${1:-}"
DIR2="${2:-}"

[[ -n "$DIR1" && -n "$DIR2" ]] || die \
    "Usage: $0 DIRECTORY1 DIRECTORY2"

[[ -d "$DIR1" ]] || die "Directory does not exist: $DIR1"
[[ -d "$DIR2" ]] || die "Directory does not exist: $DIR2"

DIR1="$(realpath "$DIR1")"
DIR2="$(realpath "$DIR2")"

log_header "$DIR1 <-> $DIR2"

echo "Mode         : READ-ONLY"
echo "Purpose      : Compare document candidates only, using SHA-256."
echo
echo "Directory 1  : $DIR1"
echo "Directory 2  : $DIR2"
echo
echo "Included extensions:"
echo "  pdf doc docx xls xlsx xlsm ppt pptx odt ods odp rtf txt csv"
echo "  html htm mht mhtml"
echo "  zip rar 7z"
echo

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

D1="$WORK_DIR/d1.tsv"
D2="$WORK_DIR/d2.tsv"
H1="$WORK_DIR/h1.tsv"
H2="$WORK_DIR/h2.tsv"

REPORT_TXT="$LOG_DIR/${SCRIPT_NAME%.sh}_report_${TIMESTAMP}.txt"
REPORT_CSV="$LOG_DIR/${SCRIPT_NAME%.sh}_report_${TIMESTAMP}.csv"

cat > "$REPORT_CSV" <<'CSV'
classification,dir1_path,dir2_path,dir1_size,dir2_size,dir1_sha256,dir2_sha256
CSV

find_docs() {
    find "$1" -type f \( \
        -iname '*.pdf' -o \
        -iname '*.doc' -o -iname '*.docx' -o \
        -iname '*.xls' -o -iname '*.xlsx' -o -iname '*.xlsm' -o \
        -iname '*.ppt' -o -iname '*.pptx' -o \
        -iname '*.odt' -o -iname '*.ods' -o -iname '*.odp' -o \
        -iname '*.rtf' -o -iname '*.txt' -o -iname '*.csv' -o \
        -iname '*.html' -o -iname '*.htm' -o \
        -iname '*.mht' -o -iname '*.mhtml' -o \
        -iname '*.zip' -o -iname '*.rar' -o -iname '*.7z' \
        \) -printf '%P\t%p\t%s\n' 2>/dev/null | sort
}

echo "Building document candidate inventories..."
find_docs "$DIR1" > "$D1"
find_docs "$DIR2" > "$D2"

echo "Document candidates in Directory 1 : $(wc -l < "$D1")"
echo "Document candidates in Directory 2 : $(wc -l < "$D2")"
echo

echo "Calculating SHA-256 hashes..."

while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    hash="$(sha256sum -- "$path" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\n' "$rel" "$path" "$size" "$hash"
done < "$D1" > "$H1"

while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    hash="$(sha256sum -- "$path" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\n' "$rel" "$path" "$size" "$hash"
done < "$D2" > "$H2"

declare -A P1 S1 X1
declare -A P2 S2 X2
declare -A BYHASH1 BYHASH2

while IFS=$'\t' read -r rel path size hash; do
    P1["$rel"]="$path"; S1["$rel"]="$size"; X1["$rel"]="$hash"
    BYHASH1["$hash"]+="${rel}"$'\n'
done < "$H1"

while IFS=$'\t' read -r rel path size hash; do
    P2["$rel"]="$path"; S2["$rel"]="$size"; X2["$rel"]="$hash"
    BYHASH2["$hash"]+="${rel}"$'\n'
done < "$H2"

exact=0
same_name_diff=0
different_name_same=0
only1=0
only2=0

{
    echo "============================================================"
    echo "DOCUMENT DIRECTORY COMPARISON"
    echo "============================================================"
    echo "Directory 1 : $DIR1"
    echo "Directory 2 : $DIR2"
    echo "Generated   : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo

    echo "EXACT_DUPLICATE"
    echo "---------------"
    for rel in "${!X1[@]}"; do
        if [[ -n "${X2[$rel]+x}" && "${X1[$rel]}" == "${X2[$rel]}" ]]; then
            exact=$((exact+1))
            printf 'DIR1: %s\nDIR2: %s\nSHA256: %s\n\n' \
                "${P1[$rel]}" "${P2[$rel]}" "${X1[$rel]}"
            printf '"EXACT_DUPLICATE","%s","%s","%s","%s","%s","%s"\n' \
                "${P1[$rel]}" "${P2[$rel]}" "${S1[$rel]}" "${S2[$rel]}" \
                "${X1[$rel]}" "${X2[$rel]}" >> "$REPORT_CSV"
        fi
    done

    echo
    echo "SAME_NAME_DIFFERENT_CONTENT"
    echo "---------------------------"
    for rel in "${!X1[@]}"; do
        if [[ -n "${X2[$rel]+x}" && "${X1[$rel]}" != "${X2[$rel]}" ]]; then
            same_name_diff=$((same_name_diff+1))
            printf 'RELATIVE PATH: %s\nDIR1: %s\nSIZE: %s\nSHA256: %s\nDIR2: %s\nSIZE: %s\nSHA256: %s\n\n' \
                "$rel" "${P1[$rel]}" "${S1[$rel]}" "${X1[$rel]}" \
                "${P2[$rel]}" "${S2[$rel]}" "${X2[$rel]}"
            printf '"SAME_NAME_DIFFERENT_CONTENT","%s","%s","%s","%s","%s","%s"\n' \
                "${P1[$rel]}" "${P2[$rel]}" "${S1[$rel]}" "${S2[$rel]}" \
                "${X1[$rel]}" "${X2[$rel]}" >> "$REPORT_CSV"
        fi
    done

    echo
    echo "DIFFERENT_NAME_SAME_CONTENT"
    echo "---------------------------"
    for hash in "${!BYHASH1[@]}"; do
        [[ -n "${BYHASH2[$hash]+x}" ]] || continue
        while IFS= read -r r1; do
            [[ -n "$r1" ]] || continue
            while IFS= read -r r2; do
                [[ -n "$r2" || -z "$r2" ]] || true
                [[ -n "$r2" ]] || continue
                [[ "$r1" == "$r2" ]] && continue
                different_name_same=$((different_name_same+1))
                printf 'DIR1: %s\nDIR2: %s\nSHA256: %s\n\n' \
                    "${P1[$r1]}" "${P2[$r2]}" "$hash"
                printf '"DIFFERENT_NAME_SAME_CONTENT","%s","%s","%s","%s","%s","%s"\n' \
                    "${P1[$r1]}" "${P2[$r2]}" "${S1[$r1]}" "${S2[$r2]}" \
                    "$hash" "$hash" >> "$REPORT_CSV"
            done <<< "${BYHASH2[$hash]}"
        done <<< "${BYHASH1[$hash]}"
    done

    echo
    echo "DIRECTORY 1 ONLY"
    echo "---------------"
    for rel in "${!X1[@]}"; do
        [[ -n "${X2[$rel]+x}" ]] || {
            only1=$((only1+1))
            printf '%s\n' "${P1[$rel]}"
        }
    done

    echo
    echo "DIRECTORY 2 ONLY"
    echo "---------------"
    for rel in "${!X2[@]}"; do
        [[ -n "${X1[$rel]+x}" ]] || {
            only2=$((only2+1))
            printf '%s\n' "${P2[$rel]}"
        }
    done

    echo
    echo "SUMMARY COUNTS"
    echo "--------------"
    echo "Exact duplicates              : $exact"
    echo "Same name, different content  : $same_name_diff"
    echo "Different name, same content  : $different_name_same"
    echo "Directory 1 document only     : $only1"
    echo "Directory 2 document only     : $only2"
} | tee "$REPORT_TXT"

echo
echo "Text report : $REPORT_TXT"
echo "CSV report  : $REPORT_CSV"

log_footer "SUCCESS"
