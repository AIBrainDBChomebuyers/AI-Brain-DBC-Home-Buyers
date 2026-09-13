# Setting up Supabase

Start to finish. Roughly 30 minutes, most of it waiting for the project to
provision.

**Before you start**, two things are missing on this machine and step 0 fixes
both. Neither is optional.

---

## 0. Install what the scripts need

```bash
brew install libpq && brew link --force libpq   # gives you psql
/usr/bin/python3 -m pip install --user "psycopg[binary]"
```

`psql` runs the migrations. `psycopg` is what the loader connects with — it
is not installed, and the loader will tell you so and stop rather than fail
halfway.

Note the interpreter: `/usr/bin/python3`, not the Homebrew one. The project's
dependencies live there. `rebuild_all.sh` already probes for the right one;
these commands do not, so be explicit.

*If you would rather not install psql*, every migration can be pasted into
Supabase's SQL editor instead — see the note at step 3.

---

## 1. Create the project

1. supabase.com → **New project**
2. Name it, choose a region near Baltimore (`us-east-1`), set a database
   password and **save it somewhere** — Supabase shows it once.
3. Wait for provisioning.

Then **Settings → Database → Connection string** and copy two of them:

| Which | Port | Used for |
|---|---|---|
| **Direct** | 5432 | migrations, loading data |
| **Transaction pooler** | 6543 | the API |

The distinction matters. The API uses the pooler, which is only safe because
`withRoles()` sets `app.roles` with `SET LOCAL` inside an explicit
transaction — a plain `SET` would leak one user's roles to whoever gets that
connection next. Migrations and the loader need the direct connection.

Put both in `.env`:

```bash
cp .env.example .env
```

```
DATABASE_URL_DIRECT=postgresql://postgres:YOURPASSWORD@db.YOURPROJECT.supabase.co:5432/postgres
DATABASE_URL_POOLER=postgresql://postgres.YOURPROJECT:YOURPASSWORD@REGION.pooler.supabase.com:6543/postgres
```

---

## 2. Check one thing before running anything

In the Supabase SQL editor:

```sql
SELECT current_user, rolbypassrls
FROM   pg_roles
WHERE  rolname = current_user;
```

This decides the order of the next two steps, and it is the single most
likely thing to trip you up.

**Why.** `003_enable_rls.sql` turns on row-level security and **forces** it,
which binds the table owner too. Every policy in this schema is `FOR SELECT`
— there are no INSERT or UPDATE policies at all. So a loader without
`BYPASSRLS` does not merely see fewer rows: its
`INSERT … ON CONFLICT DO UPDATE` **fails outright**.

- **`rolbypassrls = true`** → go to step 3a.
- **`rolbypassrls = false`** → go to step 3b.

---

## 3a. Migrate, then load

```bash
npm run db:migrate
npm run db:load
```

That runs `001` → `005` on the direct connection, then upserts 5,279 rows
across 16 tables.

**Without psql:** open each file in `database/postgres/migrations/` in order
— `001_create_tables.sql`, `002_create_indexes.sql`, `003_enable_rls.sql`,
`004_create_views.sql`, `005_add_comments.sql` — and paste each into the SQL
editor. Then run `npm run db:load` for the data.

## 3b. Migrate, load, then lock

```bash
npm run db:migrate -- --pre-rls    # 001, 002
npm run db:load                    # rows go in while the door is open
npm run db:migrate -- --rls-only   # 003, 004, 005
```

The database ends up in exactly the same state. You just write the rows
before the policies are in force.

Either way, `003` reports what it did:

```
NOTICE:  loader role postgres already bypasses RLS
```

or, if it could not grant the exemption, a warning naming this workaround.

---

## 4. Give the application role a password

The migration creates `ai_brain_app` as `NOLOGIN` on purpose, so no password
ends up in version control. Grant it one now, in the SQL editor:

```sql
ALTER ROLE ai_brain_app LOGIN PASSWORD 'pick-something-long';
```

Put the same value in `.env` as `PGPASSWORD`.

This is the role the API connects as. It holds `SELECT` and nothing else, on
16 tables and 7 views. Never point the API at the `postgres` role — it
bypasses RLS, which silently disables every policy in the database.

---

## 5. Verify it actually works

Not "did it run" — did the permission boundary behave. In the SQL editor:

```sql
-- everything, as the owner
SELECT count(*) FROM deal_portfolio;                       -- expect 256

-- now as the application sees it, for a VA
SET LOCAL app.roles = 'va';
SELECT count(*) FROM deal_portfolio;                       -- expect 256
SELECT count(*) FROM deal_economics;                       -- expect 0

-- and with no role set at all
RESET app.roles;
SELECT count(*) FROM deal_portfolio;                       -- expect 0
```

Wrap those in `BEGIN; … COMMIT;` so `SET LOCAL` applies.

**What each proves.** A VA can see the property list but not a single row of
economics — that table carries profit and margin. And an unset role returns
nothing rather than everything: `current_setting` yields NULL, the array
overlap yields NULL, the row is excluded. It fails closed.

If the third query returns 256, RLS is not on. Stop and check that `003` ran.

---

## 6. Point the API at it

```bash
npm run dev:backend
curl localhost:4000/api/health
```

Expect `{"status":"ok","checks":{"postgres":true}}`.

---

## If the data is missing

`database/postgres/tables/*.json` is deliberately not in git — it carries the
names of people who sold houses to DBC. On a fresh clone:

```bash
npm run db:sync     # copies the current export from the extraction pipeline
```

That needs `../Data Retrieval/extraction_tool` beside this folder. If you do
not have it, someone who does has to run the pipeline and hand you the
export.

---

## What is still not set up after this

- **Identity.** Supabase ships its own auth and the code assumes Keycloak.
  Pick one before wiring login.
- **Embeddings.** 3,842 passages, nothing generated. Semantic search returns
  nothing until that job runs.
- **The consolidation.** Ten collections still live in the MongoDB export.
  Standing up Supabase does not wait on it — the 16 relational tables are
  unchanged either way.
