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

# Use an interpreter that actually has psycopg. A bare `python3` may resolve
# to one without it — on this machine Homebrew's comes first on PATH while
# the dependency lives under /usr/bin/python3. Override with PY=... if yours
# differs.
PY="${PY:-$(for c in /usr/bin/python3 python3 python3.12 python3.11; do
      command -v "$c" >/dev/null 2>&1 && "$c" -c "import psycopg" 2>/dev/null && echo "$c" && break
    done)}"
if [ -z "$PY" ]; then
  echo "no python3 with psycopg found. Install it:" >&2
  echo "  /usr/bin/python3 -m pip install --user 'psycopg[binary]'" >&2
  exit 1
fi

DSN="${DATABASE_URL_DIRECT:-postgresql://${PG_OWNER_USER}:${PG_OWNER_PASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}"
"$PY" database/postgres/migrations/load_data.py --dsn "$DSN"
echo "done."
