#!/usr/bin/env bash
set -euo pipefail

FEDRA="${1:-${FEDRA_ROOT:-}}"
REQUIRE_ORACLE="${2:-}"

if [[ -z "$FEDRA" ]]; then
    echo "Usage: $0 /path/to/FEDRA_ROOT [--require-oracle]" >&2
    exit 2
fi
FEDRA="$(cd "$FEDRA" && pwd)"

if [[ ! -x "$FEDRA/src/makeall.sh" ]]; then
    echo "[error] makeall.sh not found" >&2
    exit 1
fi

out="$(cd "$FEDRA/src" && ./makeall.sh check)"
printf '%s\n' "$out"

errors="$(printf '%s\n' "$out" | grep 'ERROR!' || true)"
if [[ -z "$errors" ]]; then
    echo "[ok] All checked FEDRA components are present."
    exit 0
fi

if [[ "$REQUIRE_ORACLE" != "--require-oracle" ]]; then
    non_oracle="$(printf '%s\n' "$errors" | grep -Ev '/(o2root|fb2db|scan2db)\.\.\.ERROR!' || true)"
    if [[ -z "$non_oracle" ]]; then
        echo "[ok] Core FEDRA is complete. Only optional Oracle applications are missing."
        exit 0
    fi
fi

echo "[error] Missing FEDRA components remain." >&2
exit 1
