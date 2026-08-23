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
echo "Purpose      : Compare files by SHA-256 and relative name/path."
echo
echo "Directory 1  : $DIR1"
echo "Directory 2  : $DIR2"
echo

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

DIR1_LIST="$WORK_DIR/dir1.tsv"
DIR2_LIST="$WORK_DIR/dir2.tsv"
HASH1="$WORK_DIR/hash1.tsv"
HASH2="$WORK_DIR/hash2.tsv"

REPORT_TXT="$LOG_DIR/${SCRIPT_NAME%.sh}_report_${TIMESTAMP}.txt"
REPORT_CSV="$LOG_DIR/${SCRIPT_NAME%.sh}_report_${TIMESTAMP}.csv"

: > "$REPORT_TXT"
: > "$REPORT_CSV"

echo "classification,dir1_path,dir2_path,dir1_size,dir2_size,dir1_sha256,dir2_sha256" \
    > "$REPORT_CSV"

echo "Building file inventories..."

# Generate relative path + absolute path + size.
find "$DIR1" -type f -printf '%P\t%p\t%s\n' 2>/dev/null |
    sort > "$DIR1_LIST"

find "$DIR2" -type f -printf '%P\t%p\t%s\n' 2>/dev/null |
    sort > "$DIR2_LIST"

COUNT1="$(wc -l < "$DIR1_LIST")"
COUNT2="$(wc -l < "$DIR2_LIST")"

echo "Files in Directory 1 : $COUNT1"
echo "Files in Directory 2 : $COUNT2"
echo

echo "Calculating SHA-256 hashes for Directory 1..."
while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    hash="$(sha256sum -- "$path" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\n' "$rel" "$path" "$size" "$hash"
done < "$DIR1_LIST" > "$HASH1"

echo "Calculating SHA-256 hashes for Directory 2..."
while IFS=$'\t' read -r rel path size; do
    [[ -n "$path" ]] || continue
    hash="$(sha256sum -- "$path" | awk '{print $1}')"
    printf '%s\t%s\t%s\t%s\n' "$rel" "$path" "$size" "$hash"
done < "$DIR2_LIST" > "$HASH2"

declare -A D1_PATH D1_SIZE D1_HASH
declare -A D2_PATH D2_SIZE D2_HASH
declare -A HASH_TO_D1 HASH_TO_D2

while IFS=$'\t' read -r rel path size hash; do
    D1_PATH["$rel"]="$path"
    D1_SIZE["$rel"]="$size"
    D1_HASH["$rel"]="$hash"
    HASH_TO_D1["$hash"]+="${rel}"$'\n'
done < "$HASH1"

while IFS=$'\t' read -r rel path size hash; do
    D2_PATH["$rel"]="$path"
    D2_SIZE["$rel"]="$size"
    D2_HASH["$rel"]="$hash"
    HASH_TO_D2["$hash"]+="${rel}"$'\n'
done < "$HASH2"

exact=0
same_name_diff=0
different_name_same=0
dir1_only=0
dir2_only=0

{
    echo "============================================================"
    echo "DIRECTORY COMPARISON REPORT"
    echo "============================================================"
    echo "Directory 1 : $DIR1"
    echo "Directory 2 : $DIR2"
    echo "Generated   : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo

    echo "SUMMARY"
    echo "-------"
    echo "Directory 1 files : $COUNT1"
    echo "Directory 2 files : $COUNT2"
    echo

    echo "EXACT_DUPLICATE"
    echo "---------------"

    for rel in "${!D1_HASH[@]}"; do
        hash="${D1_HASH[$rel]}"

        if [[ -n "${D2_HASH[$rel]+x}" && "${D2_HASH[$rel]}" == "$hash" ]]; then
            exact=$((exact + 1))
            printf 'DIR1: %s\nDIR2: %s\nSHA256: %s\n\n' \
                "${D1_PATH[$rel]}" "${D2_PATH[$rel]}" "$hash"

            printf '"EXACT_DUPLICATE","%s","%s","%s","%s","%s","%s"\n' \
                "${D1_PATH[$rel]}" "${D2_PATH[$rel]}" \
                "${D1_SIZE[$rel]}" "${D2_SIZE[$rel]}" \
                "$hash" "$hash" >> "$REPORT_CSV"
        fi
    done

    echo
    echo "SAME_NAME_DIFFERENT_CONTENT"
    echo "---------------------------"

    for rel in "${!D1_HASH[@]}"; do
        if [[ -n "${D2_HASH[$rel]+x}" && "${D2_HASH[$rel]}" != "${D1_HASH[$rel]}" ]]; then
            same_name_diff=$((same_name_diff + 1))
            printf 'RELATIVE PATH: %s\n' "$rel"
            printf 'DIR1: %s\nSIZE: %s\nSHA256: %s\n' \
                "${D1_PATH[$rel]}" "${D1_SIZE[$rel]}" "${D1_HASH[$rel]}"
            printf 'DIR2: %s\nSIZE: %s\nSHA256: %s\n\n' \
                "${D2_PATH[$rel]}" "${D2_SIZE[$rel]}" "${D2_HASH[$rel]}"

            printf '"SAME_NAME_DIFFERENT_CONTENT","%s","%s","%s","%s","%s","%s"\n' \
                "${D1_PATH[$rel]}" "${D2_PATH[$rel]}" \
                "${D1_SIZE[$rel]}" "${D2_SIZE[$rel]}" \
                "${D1_HASH[$rel]}" "${D2_HASH[$rel]}" >> "$REPORT_CSV"
        fi
    done

    echo
    echo "DIFFERENT_NAME_SAME_CONTENT"
    echo "---------------------------"

    for hash in "${!HASH_TO_D1[@]}"; do
        [[ -n "${HASH_TO_D2[$hash]+x}" ]] || continue

        while IFS= read -r rel1; do
            [[ -n "$rel1" ]] || continue

            while IFS= read -r rel2; do
                [[ -n "$rel2" ]] || continue
                [[ "$rel1" == "$rel2" ]] && continue

                different_name_same=$((different_name_same + 1))

                printf 'DIR1: %s\nDIR2: %s\nSHA256: %s\n\n' \
                    "${D1_PATH[$rel1]}" "${D2_PATH[$rel2]}" "$hash"

                printf '"DIFFERENT_NAME_SAME_CONTENT","%s","%s","%s","%s","%s","%s"\n' \
                    "${D1_PATH[$rel1]}" "${D2_PATH[$rel2]}" \
                    "${D1_SIZE[$rel1]}" "${D2_SIZE[$rel2]}" \
                    "$hash" "$hash" >> "$REPORT_CSV"

            done <<< "${HASH_TO_D2[$hash]}"
        done <<< "${HASH_TO_D1[$hash]}"
    done

    echo
    echo "DIRECTORY 1 ONLY"
    echo "---------------"

    for rel in "${!D1_HASH[@]}"; do
        if [[ -z "${D2_HASH[$rel]+x}" ]]; then
            dir1_only=$((dir1_only + 1))
            printf '%s\n' "${D1_PATH[$rel]}"
        fi
    done

    echo
    echo "DIRECTORY 2 ONLY"
    echo "---------------"

    for rel in "${!D2_HASH[@]}"; do
        if [[ -z "${D1_HASH[$rel]+x}" ]]; then
            dir2_only=$((dir2_only + 1))
            printf '%s\n' "${D2_PATH[$rel]}"
        fi
    done

    echo
    echo "SUMMARY COUNTS"
    echo "--------------"
    echo "Exact duplicates              : $exact"
    echo "Same name, different content  : $same_name_diff"
    echo "Different name, same content  : $different_name_same"
    echo "Directory 1 only              : $dir1_only"
    echo "Directory 2 only              : $dir2_only"

} | tee "$REPORT_TXT"

echo
echo "Detailed text report : $REPORT_TXT"
echo "CSV report            : $REPORT_CSV"

log_footer "SUCCESS"
