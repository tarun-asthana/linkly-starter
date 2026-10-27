#!/usr/bin/env bash
# Dump the Linkly database through the admin network into ./backups.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p backups
out="backups/linkly-$(date +%Y%m%d-%H%M%S).sql.gz"

if ! docker run --rm --network admin \
  --cap-drop ALL --security-opt no-new-privileges --read-only --user postgres \
  -v "$PWD/secrets/db_password:/run/secrets/db_password:ro" \
  postgres:16-alpine \
  sh -c 'PGPASSWORD="$(cat /run/secrets/db_password)" pg_dump -h db -U linkly linkly' \
  | gzip > "$out.part"; then
  rm -f "$out.part"
  echo "Backup failed" >&2
  exit 1
fi
mv "$out.part" "$out"

echo "Backup written: $out ($(du -h "$out" | cut -f1))"
