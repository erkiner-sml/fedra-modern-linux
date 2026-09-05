#!/usr/bin/env bash
set -euo pipefail

FEDRA="${1:-${FEDRA_ROOT:-}}"
if [[ -z "$FEDRA" ]]; then
    echo "Usage: $0 /path/to/FEDRA_ROOT" >&2
    exit 2
fi
FEDRA="$(cd "$FEDRA" && pwd)"

if ! command -v root-config >/dev/null 2>&1; then
    echo "[error] root-config is not in PATH. Source ROOT's thisroot.sh first." >&2
    exit 1
fi

if [[ ! -d "$FEDRA/src" ]]; then
    echo "[error] $FEDRA does not look like FEDRA_ROOT" >&2
    exit 1
fi

export FEDRA_ROOT="$FEDRA"
export ROOTSYS="${ROOTSYS:-$(root-config --prefix)}"
export PATH="$ROOTSYS/bin:$FEDRA_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$ROOTSYS/lib:$FEDRA_ROOT/lib:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="$FEDRA_ROOT/python:${PYTHONPATH:-}"

mkdir -p "$FEDRA_ROOT/bin" "$FEDRA_ROOT/lib" "$FEDRA_ROOT/include"

echo "[build] ROOT $(root-config --version)"
echo "[build] FEDRA_ROOT=$FEDRA_ROOT"

# The archived installer also prepares include/config symlinks. It may return
# non-zero if optional components are unavailable, so we perform a second,
# explicit build pass afterwards.
if [[ -x "$FEDRA_ROOT/install.sh" ]]; then
    echo "[build] Running FEDRA install.sh preparation/build pass"
    (cd "$FEDRA_ROOT" && ./install.sh) || {
        echo "[warn] install.sh reported an error; continuing with explicit makeall.sh pass."
    }
fi

if [[ ! -x "$FEDRA_ROOT/src/makeall.sh" ]]; then
    echo "[error] src/makeall.sh is missing or not executable." >&2
    exit 1
fi

echo "[build] Running makeall.sh"
(cd "$FEDRA_ROOT/src" && ./makeall.sh)

# Old ROOT dictionary generators leave PCMs in each source directory.
# Copy any remaining ones into FEDRA/lib so Cling can find them at runtime.
find "$FEDRA_ROOT/src" -type f -name '*_rdict.pcm' -exec cp -f {} "$FEDRA_ROOT/lib/" \;

echo "[build] Complete."
echo "[next] $PWD/scripts/check-fedra.sh \"$FEDRA_ROOT\""
