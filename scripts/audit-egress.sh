#!/bin/sh
# Audit sandbox egress (Open + audit posture).
# Usage: ./scripts/audit-egress.sh [SANDBOX]  (default: openclaw-sbx)
set -eu
SBX="${1:-openclaw-sbx}"
echo "== policy (wide) =="
sbx policy ls "$SBX" --wide
echo "== checks =="
for target in localhost:11434 api.github.com registry.npmjs.org pypi.org; do
  sbx policy check network --sandbox "$SBX" "$target" || true
done
echo "== recent log (50) =="
sbx policy log "$SBX" --limit 50 || true
