#!/usr/bin/env bash
set -euo pipefail

FEDRA="${1:-${FEDRA_ROOT:-}}"

if [[ -z "$FEDRA" ]]; then
    echo "Usage: $0 /path/to/fedra"
    echo "or export FEDRA_ROOT first."
    exit 1
fi

if [[ ! -f "$FEDRA/src/libEDA/EdbEDAMainTab.C" ]]; then
    echo "ERROR: FEDRA source not found:"
    echo "  $FEDRA/src/libEDA/EdbEDAMainTab.C"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_FILE="$REPO_DIR/patches/eda-root6-x11-badwindow.patch"

cd "$FEDRA"

if grep -q 'fMainFrame->DontCallClose();' src/libEDA/EdbEDAMainTab.C; then
    echo "EDA X11 BadWindow fix already applied."
    exit 0
fi

patch -p1 --forward < "$PATCH_FILE"

echo "EDA ROOT6/X11 BadWindow compatibility fix applied."
echo
echo "Rebuild with:"
echo "  cd \$FEDRA_ROOT/src/libEDA && make -j1"
