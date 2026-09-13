#!/usr/bin/env bash
# Drop everything and rebuild. Development only — it runs the rollbacks in
# reverse order, which destroys all data.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

if [ "${NODE_ENV:-development}" = "production" ]; then
  echo "refusing to reset a production environment" >&2
  exit 1
fi
read -r -p "This destroys every row in the database. Type 'reset' to continue: " ok
[ "$ok" = "reset" ] || { echo "cancelled"; exit 1; }

DSN="${DATABASE_URL_DIRECT:-postgresql://${PG_OWNER_USER}:${PG_OWNER_PASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}"
for f in $(ls -r database/postgres/migrations/rollback/*.sql); do
  echo "   $(basename "$f")"; psql "$DSN" -v ON_ERROR_STOP=1 -q -f "$f"
done
echo "dropped. next: npm run db:migrate && npm run db:load"
