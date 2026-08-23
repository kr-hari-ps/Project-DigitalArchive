#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DIR1="${1:-}"
DIR2="${2:-}"
LABEL1="${3:-DEVICE1}"
LABEL2="${4:-DEVICE2}"

[[ -n "$DIR1" && -n "$DIR2" ]] || die \
    "Usage: $0 DIRECTORY1 DIRECTORY2 [LABEL1] [LABEL2]"
[[ -d "$DIR1" ]] || die "Directory does not exist: $DIR1"
[[ -d "$DIR2" ]] || die "Directory does not exist: $DIR2"

DIR1="$(realpath "$DIR1")"
DIR2="$(realpath "$DIR2")"

log_header "$DIR1 <-> $DIR2"

echo "Mode         : READ-ONLY"
echo "Purpose      : Build a CSV review sheet for document candidates from two source trees."
echo "Source 1     : $LABEL1 = $DIR1"
echo "Source 2     : $LABEL2 = $DIR2"
echo

REPORT_CSV="$LOG_DIR/${SCRIPT_NAME%.sh}_${LABEL1}_${LABEL2}_${TIMESTAMP}.csv"
echo '"record_id","source","relative_path","full_path","filename","extension","size_bytes","sha256","duplicate_group","duplicate_status","keep_decision","notes"' > "$REPORT_CSV"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
D1="$WORK_DIR/d1.tsv"
D2="$WORK_DIR/d2.tsv"

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

find_docs "$DIR1" > "$D1"
find_docs "$DIR2" > "$D2"

declare -A P1 S1 H1 P2 S2 H2
declare -A BYHASH1 BYHASH2 SEEN

while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    h="$(sha256sum -- "$path" | awk '{print $1}')"
    P1["$rel"]="$path"; S1["$rel"]="$size"; H1["$rel"]="$h"
    BYHASH1["$h"]+="${rel}"$'\n'
done < "$D1"

while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    h="$(sha256sum -- "$path" | awk '{print $1}')"
    P2["$rel"]="$path"; S2["$rel"]="$size"; H2["$rel"]="$h"
    BYHASH2["$h"]+="${rel}"$'\n'
done < "$D2"

csvq() {
    local s="$1"
    s="${s//\"/\"\"}"
    printf '"%s"' "$s"
}

get_ext() {
    local f="${1##*/}"
    if [[ "$f" != *.* || "$f" == .* ]]; then
        printf ''
    else
        printf '%s' "${f##*.}" | tr '[:upper:]' '[:lower:]'
    fi
}

emit() {
    local source="$1" rel="$2" path="$3" size="$4" hash="$5"
    local group="$6" status="$7" keep="$8" notes="$9"
    local filename="${rel##*/}" ext
    ext="$(get_ext "$filename")"
    record_num=$((record_num + 1))
    {
        csvq "$record_num"; printf ','
        csvq "$source"; printf ','
        csvq "$rel"; printf ','
        csvq "$path"; printf ','
        csvq "$filename"; printf ','
        csvq "$ext"; printf ','
        csvq "$size"; printf ','
        csvq "$hash"; printf ','
        csvq "$group"; printf ','
        csvq "$status"; printf ','
        csvq "$keep"; printf ','
        csvq "$notes"; printf '\n'
    } >> "$REPORT_CSV"
}

record_num=0
dup_groups=0

# Exact-content duplicates across the two trees.
for hash in "${!BYHASH1[@]}"; do
    [[ -n "${BYHASH2[$hash]+x}" ]] || continue
    dup_groups=$((dup_groups + 1))
    group="DUP-$(printf '%04d' "$dup_groups")"

    while IFS= read -r r1; do
        [[ -n "$r1" ]] || continue
        while IFS= read -r r2; do
            [[ -n "$r2" ]] || continue
            note="Exact-content duplicate; review which source should be kept."
            [[ "$r1" == "$r2" ]] && note="Exact-content duplicate at same relative path; review."
            emit "$LABEL1" "$r1" "${P1[$r1]}" "${S1[$r1]}" "$hash" \
                 "$group" "DUPLICATE_EXACT" "REVIEW" "$note"
            emit "$LABEL2" "$r2" "${P2[$r2]}" "${S2[$r2]}" "$hash" \
                 "$group" "DUPLICATE_EXACT" "REVIEW" "$note"
        done <<< "${BYHASH2[$hash]}"
    done <<< "${BYHASH1[$hash]}"

    while IFS= read -r r1; do [[ -n "$r1" ]] && SEEN["$LABEL1|$r1"]=1; done <<< "${BYHASH1[$hash]}"
    while IFS= read -r r2; do [[ -n "$r2" ]] && SEEN["$LABEL2|$r2"]=1; done <<< "${BYHASH2[$hash]}"
done

for rel in "${!P1[@]}"; do
    [[ -n "${SEEN["$LABEL1|$rel"]+x}" ]] && continue
    emit "$LABEL1" "$rel" "${P1[$rel]}" "${S1[$rel]}" "${H1[$rel]}" \
         "" "UNIQUE_TO_SOURCE" "YES" "No exact-content match in $LABEL2."
done

for rel in "${!P2[@]}"; do
    [[ -n "${SEEN["$LABEL2|$rel"]+x}" ]] && continue
    emit "$LABEL2" "$rel" "${P2[$rel]}" "${S2[$rel]}" "${H2[$rel]}" \
         "" "UNIQUE_TO_SOURCE" "YES" "No exact-content match in $LABEL1."
done

echo "CSV created : $REPORT_CSV"
echo "Candidates  : $LABEL1=$(wc -l < "$D1"), $LABEL2=$(wc -l < "$D2")"
echo "Dup groups  : $dup_groups"
echo "For duplicates, edit keep_decision as YES/NO/REVIEW."
log_footer "SUCCESS"
