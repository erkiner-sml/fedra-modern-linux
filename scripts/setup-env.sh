#!/usr/bin/env bash
# Source this file:
#   source scripts/setup-env.sh /path/to/fedra /path/to/root [/path/to/instantclient]

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script must be sourced:" >&2
    echo "  source $0 /path/to/fedra /path/to/root [/path/to/instantclient]" >&2
    exit 2
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: source ${BASH_SOURCE[0]} FEDRA_ROOT ROOTSYS [OCCIHOME]" >&2
    return 2
fi

export FEDRA_ROOT="$(cd "$1" && pwd)"
export ROOTSYS="$(cd "$2" && pwd)"

if [[ -f "$ROOTSYS/bin/thisroot.sh" ]]; then
    # shellcheck disable=SC1090
    source "$ROOTSYS/bin/thisroot.sh"
fi

export PATH="$ROOTSYS/bin:$FEDRA_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$ROOTSYS/lib:$FEDRA_ROOT/lib:${LD_LIBRARY_PATH:-}"
export PYTHONPATH="$FEDRA_ROOT/python:${PYTHONPATH:-}"

if [[ $# -eq 3 ]]; then
    export OCCIHOME="$(cd "$3" && pwd)"
    export ORACLE_HOME="$OCCIHOME"
    export PATH="$OCCIHOME:$PATH"
    export LD_LIBRARY_PATH="$OCCIHOME:$LD_LIBRARY_PATH"
fi

echo "FEDRA_ROOT=$FEDRA_ROOT"
echo "ROOTSYS=$ROOTSYS"
command -v root-config >/dev/null 2>&1 && echo "ROOT=$(root-config --version)"
