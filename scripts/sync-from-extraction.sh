#!/usr/bin/env bash
# Refresh database/ from the extraction pipeline.
#
# The seed data in database/ is generated, not written by hand: it comes from
# ../Data Retrieval/extraction_tool, which rebuilds it every time new
# documents arrive. This copies the current output across. Run the pipeline
# first (its own rebuild_all.sh), then this, then npm run db:load.
set -euo pipefail
cd "$(dirname "$0")/.."

# The Mongo half below is temporary. The extraction pipeline still emits ten
# collections; once the consolidation in docs/SINGLE_STORE_MIGRATION.md is
# done it will emit them as Postgres tables and these lines go away.
SRC="../Data Retrieval/extraction_tool/client_review/db_export"
[ -d "$SRC" ] || { echo "extraction output not found at $SRC" >&2; exit 1; }

# --delete keeps the generated set honest: a migration the generator stops
# emitting should disappear here too. But it deleted a hand-written 007 on its
# first run, silently, and the next psql invocation failed on a missing file.
# The generator owns 001-005; anything numbered 006 and up is a hand-written
# fix-up against an already-loaded database and is protected from deletion.
rsync -a --delete --filter='protect 0[0-9][0-9]_*.sql' \
      --filter='protect rollback/0[0-9][0-9]_*.sql' \
      "$SRC/postgres/migrations/"   database/postgres/migrations/
rsync -a --delete "$SRC/postgres/tables/"       database/postgres/tables/
rsync -a --delete "$SRC/mongodb/migrations/"    database/mongodb/migrations/
rsync -a --delete "$SRC/mongodb/collections/"   database/mongodb/collections/
cp "$SRC/mongodb/retrieval.py" database/mongodb/retrieval.py
cp "$SRC/schema.json" "$SRC/MANIFEST.json" database/

python3 - <<'PY'
import json
m = json.load(open("database/MANIFEST.json"))
print(f"  synced: {m['postgres']['tables']} tables ({m['postgres']['rows']:,} rows), "
      f"{m['mongodb']['collections']} collections ({m['mongodb']['documents']:,} documents)")
print(f"  generated {m['generated_at']}")
PY
