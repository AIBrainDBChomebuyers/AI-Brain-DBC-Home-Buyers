# AI-Brain-DBC-Home-Buyers

The AI Brain chatbot, which helps employees at DBC answer queries about their
own data. Ask it a question in plain English; it answers from the documents
and figures the business already has, and only from the parts the person
asking is allowed to see.

## Layout

    DBC AI Brain/
      backend/        Node + Express API. Auth, retrieval, the orchestrator.
      frontend/       React (Vite). Chat and the property browser.
      shared/         Constants both sides must agree on - roles, statuses.
      database/       Schema, migrations and the extracted records.
      ingestion/      How data gets in. Points at the extraction pipeline.
      infra/          docker-compose for local Postgres, Keycloak, MinIO.
      scripts/        migrate, load, reset, sync.
      docs/           Architecture, data model, access control, chatbot plan.

## Getting started

Setting up Supabase for the first time: [docs/SETUP.md](./docs/SETUP.md).

    cp .env.example .env          # fill in the blanks
    npm install
    npm run db:sync               # fetch the seed data (see below)
    npm run db:up                 # postgres, mongo, keycloak, minio
    npm run db:migrate            # schema, indexes, RLS, views
    npm run db:load               # 5279 rows + 4948 documents
    npm run dev                   # api on :4000, ui on :5173

## One database, on purpose

**Supabase Postgres**, and nothing else. 31 tables, 10,227 rows once the
consolidation is finished — deal figures, document passages and runtime
records together.

Two kinds of question, one store:

- *"Average profit by county in 2024"* is arithmetic over rows. SQL.
- *"What did the seller agree to on Hobbit Lane?"* is similarity over
  language. pgvector, 3,842 embeddings at 1536 dimensions — 22.5 MB, which
  Postgres handles without noticing.

They meet at `property_key`, so an answer can cite the document and quote the
figure in the same breath.

An earlier design split these across Postgres and MongoDB, on the grounds
that Postgres had no vector search. Supabase ships pgvector, so it does — and
a second database bought nothing but a second permission model. See
[docs/SINGLE_STORE_MIGRATION.md](./docs/SINGLE_STORE_MIGRATION.md).

## Permissions

Six roles, from section 9: executive, acquisitions, construction,
property_management, accounting, va.

Every row carries `allowed_roles`, and **the database enforces it** —
row-level security is enabled and forced on every table, with each policy
filtering on the session's `app.roles`. A query that forgets to filter
returns the same rows as one that remembers. The mistake cannot be expressed.

That now covers the document passages too, which is the main reason for
consolidating: under the old design the passage scope was enforced by
application code, and one forgotten filter exposed 3,172 of 4,948 documents.

If `app.roles` is never set the policy yields NULL and the row is excluded —
it fails closed. Roles come from the verified token and nowhere else: never
a header, never a request body.

## The seed data is not in this repo

`database/` holds the migrations but **not** the extracted records. Those are
generated, and they carry the names of people who sold houses to DBC, their
addresses and the raw text of settlement statements — which does not belong
in permanent git history.

Fetch them from the extraction pipeline instead:

    npm run db:sync     # copies the current export into database/
    npm run db:load     # upserts it into the database

## Where the data comes from

`database/` is generated, not hand-written. It is built by the extraction
pipeline in `../Data Retrieval/extraction_tool`, which reads the source PDFs
and spreadsheets and produces the JSON that lands here.

When new documents arrive:

    cd "../Data Retrieval/extraction_tool/client_review" && ./rebuild_all.sh
    cd -; npm run db:sync && npm run db:load

Both loaders upsert on a stable key, so re-running changes nothing the second
time. That is what makes the loop cheap.

## Status

- [PLAN.md](./PLAN.md) — phases, key notes, what is proven, what is blocked
- [PROGRESS.md](./PROGRESS.md) — running log, and what to pick up next
- [docs/BUILD_PLAN.md](./docs/BUILD_PLAN.md) — the full engineering plan
- [docs/CHATBOT_PLAN.md](./docs/CHATBOT_PLAN.md) — the website design

Update them alongside the work, not after.

### Summary


Scaffolded, with the database layer complete and loadable. The orchestrator
(`backend/src/services/orchestrator.js`) is a stub. Embeddings are not yet
generated - the vector indexes are declared and correct, but nothing has
populated the `embedding` field, so semantic retrieval will return nothing
until that runs. See `docs/ARCHITECTURE.md`.