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
echo "Purpose      : Count regular files and total size by extension."
echo
echo "Extension inventory:"

find "$SOURCE" -type f -printf '%s\t%f\n' 2>/dev/null |
awk -F '\t' '
{
    name=$2
    size=$1
    if (name !~ /\./) {
        ext="[no extension]"
    } else {
        ext=name
        sub(/^.*\./, "", ext)
        ext=tolower(ext)
        if (ext == "") ext="[empty extension]"
    }
    count[ext]++
    bytes[ext]+=size
}
END {
    for (ext in count)
        printf "%8d  %12.1f MB  %s\n", count[ext], bytes[ext]/1024/1024, ext
}' | sort -k3

echo
echo "Total regular files : $(find "$SOURCE" -type f 2>/dev/null | wc -l)"
echo "Total size          : $(du -sh "$SOURCE" 2>/dev/null | awk '{print $1}')"

log_footer "SUCCESS"
