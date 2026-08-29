#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

SOURCE="${1:-}"

[[ -n "$SOURCE" ]] || die "Usage: $0 DIRECTORY"
[[ -d "$SOURCE" ]] || die "Directory does not exist or is not a directory: $SOURCE"

log_header "$SOURCE"

echo "Mode         : READ-ONLY"
echo "Purpose      : Identify document candidates across the entire source tree."
echo
echo "Candidate categories:"
echo "  Office/document : pdf, doc, docx, xls, xlsx, xlsm, ppt, pptx, odt, ods, odp, rtf, txt, csv"
echo "  Web/document    : html, htm, mht, mhtml"
echo "  Archives        : zip, rar, 7z"
echo
echo "Files by candidate extension:"
echo

find "$SOURCE" -type f -printf '%p\n' 2>/dev/null |
awk '
BEGIN {
    FS="."
    OFS="\t"
}
{
    path=$0
    name=$NF
    if ($0 !~ /\./ || name == $0) next
    ext=tolower(name)

    if (ext ~ /^(pdf|doc|docx|xls|xlsx|xlsm|ppt|pptx|odt|ods|odp|rtf|txt|csv|html|htm|mht|mhtml|zip|rar|7z)$/) {
        count[ext]++
    }
}
END {
    for (ext in count)
        printf "%8d  %s\n", count[ext], ext
}' | sort -k2

echo
echo "Candidate files:"
echo "------------------------------------------------------------"

find "$SOURCE" -type f \( \
    -iname '*.pdf' -o \
    -iname '*.doc' -o -iname '*.docx' -o \
    -iname '*.xls' -o -iname '*.xlsx' -o -iname '*.xlsm' -o \
    -iname '*.ppt' -o -iname '*.pptx' -o \
    -iname '*.odt' -o -iname '*.ods' -o -iname '*.odp' -o \
    -iname '*.rtf' -o -iname '*.txt' -o -iname '*.csv' -o \
    -iname '*.html' -o -iname '*.htm' -o \
    -iname '*.mht' -o -iname '*.mhtml' -o \
    -iname '*.zip' -o -iname '*.rar' -o -iname '*.7z' \
    \) -print 2>/dev/null | sort

echo
echo "Total document/web/archive candidates:"
find "$SOURCE" -type f \( \
    -iname '*.pdf' -o \
    -iname '*.doc' -o -iname '*.docx' -o \
    -iname '*.xls' -o -iname '*.xlsx' -o -iname '*.xlsm' -o \
    -iname '*.ppt' -o -iname '*.pptx' -o \
    -iname '*.odt' -o -iname '*.ods' -o -iname '*.odp' -o \
    -iname '*.rtf' -o -iname '*.txt' -o -iname '*.csv' -o \
    -iname '*.html' -o -iname '*.htm' -o \
    -iname '*.mht' -o -iname '*.mhtml' -o \
    -iname '*.zip' -o -iname '*.rar' -o -iname '*.7z' \
    \) -type f 2>/dev/null | wc -l

log_footer "SUCCESS"
