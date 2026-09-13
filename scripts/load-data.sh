#!/usr/bin/env bash
# Load the extracted records. Safe to re-run: the loader upserts on a stable
# row_key, so a second run changes nothing. That is what makes the
# "re-extract after Dave sends more documents" loop cheap.
#
# Needs a role with BYPASSRLS, because 003 FORCEs row-level security and the
# only policies are SELECT — without it, writes fail rather than silently
# returning fewer rows.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

DSN="${DATABASE_URL_DIRECT:-postgresql://${PG_OWNER_USER}:${PG_OWNER_PASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}"
python3 database/postgres/migrations/load_data.py --dsn "$DSN"
echo "done."
