#!/usr/bin/env bash
# Create the schema. Runs as the OWNER role, not the application role.
#
# Order matters and is not alphabetical by accident:
#   001 tables      the shape
#   002 indexes     including GIN on allowed_roles, which every query uses
#   003 RLS         the permission boundary; creates the app role too
#   004 views       security_invoker, so RLS still applies through them
#   005 comments    coverage notes the text-to-SQL layer reads as context
#
# On Supabase, check BYPASSRLS before running 003 — see .env.example. If the
# loader cannot bypass, run this with --pre-rls, load, then --rls-only.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

DSN="${DATABASE_URL_DIRECT:-postgresql://${PG_OWNER_USER}:${PG_OWNER_PASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}"

case "${1:-all}" in
  --pre-rls) files="001 002" ;;
  --rls-only) files="003 004 005" ;;
  *) files="001 002 003 004 005" ;;
esac

for n in $files; do
  f=$(ls database/postgres/migrations/${n}_*.sql)
  echo "   $(basename "$f")"
  psql "$DSN" -v ON_ERROR_STOP=1 -q -f "$f"
done

echo "done. next: npm run db:load"
