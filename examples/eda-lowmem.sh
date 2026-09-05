#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   cd /path/to/reconstruction-directory
#   /path/to/eda-lowmem.sh [sampling_factor]
#
# The reconstruction directory should contain lnk.def.
# If you have lnk_std.def instead:
#   ln -s lnk_std.def lnk.def

N="${1:-20}"

if ! [[ "$N" =~ ^[1-9][0-9]*$ ]]; then
    echo "sampling_factor must be a positive integer" >&2
    exit 2
fi

if [[ ! -e lnk.def ]]; then
    echo "[error] lnk.def not found in $(pwd)" >&2
    exit 1
fi

echo "[EDA] display sample: Entry$%${N}==0 && nseg>2"
echo "[note] This is for interactive display/performance, not physics selection."

exec eda -c "Entry\$%${N}==0&&nseg>2"
