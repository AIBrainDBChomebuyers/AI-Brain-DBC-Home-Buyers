# Moving to one database

**Decision (2026-09-13):** Supabase Postgres only. MongoDB is removed and its
ten collections become tables; the 3,842 embeddings go into pgvector.

This document is the rework plan. It replaces the two-store design described
in earlier revisions of `ARCHITECTURE.md`.

---

## Why the earlier decision changed

The two-store split was justified on one sentence: *Postgres has no vector
search.* That was true of stock Postgres and it is not true of Supabase,
which ships pgvector. When the premise goes, the conclusion should go with
it.

What the numbers say now:

| | |
|---|---:|
| Documents needing a vector | **3,842** |
| Storage at 1536 dims | 22.5 MB, or ~56 MB with an HNSW index |
| Whole database once consolidated | **31 tables, 10,227 rows** |
| Supabase free tier | 500 MB |

pgvector is comfortable into the millions of rows. At 3,842 it is not
working hard, and a second database earns nothing.

## What it fixes

The weakness recorded in every planning document so far:

> MongoDB has no row-level security, and Atlas Vector Search cannot be
> fronted by a filtered view because `$vectorSearch` must run on the
> collection owning the index. So the scope is enforced in application code.
> One forgotten filter exposes 3,172 of 4,948 documents, 1,742 of which
> mention profit or a five-figure sum.

In Postgres the passages sit under the same RLS policies as the deal
figures. There is no second permission model to keep in step, no chokepoint
to protect, and no code path that can bypass it. **The hole is not mitigated;
it stops existing.**

---

## The new shape

    Supabase Postgres
      16  relational tables      5,279 rows   (unchanged)
      10  former collections     4,948 rows   → tables
           6 of them with `embedding vector(1536)`
           4 plain
       5  runtime tables         empty        (users, roles, conversations,
      ──                                       audit_logs, ingested_files)
      31  tables                10,227 rows

Tables gaining an embedding column:

| Table | Rows |
|---|---:|
| `source_documents` | 3,728 |
| `glossary` | 37 |
| `tab_relationships` | 26 |
| `ceo_narrative` | 23 |
| `ceo_conclusions` | 16 |
| `guide_sections` | 12 |

---

## One honest caveat about vectors under RLS

The filtering problem does not vanish; it changes shape, and for the better.

An HNSW index is approximate. Postgres walks the index, then applies the RLS
predicate, so a heavily-filtered query can return **fewer** rows than asked
for — a VA searching 1,776 visible documents out of 4,948 may get five hits
when they asked for eight.

The important part is the direction of the failure:

- **Mongo, filter forgotten:** returns documents the user may not read. Fails
  **open**.
- **Postgres, index filtering:** returns too few. Fails **closed**.

One is a security incident, the other is a recall complaint. Two mitigations,
and at this scale the second is the good one:

1. Raise `hnsw.ef_search`, or use pgvector 0.8's iterative index scans, which
   exist for exactly this.
2. **Skip the index.** Exact search over 3,842 vectors is 5.9M float
   operations — single-digit milliseconds. No approximation, no recall loss,
   no tuning. Build the HNSW index when the corpus is ten times larger, not
   before.

Start with exact search. It is simpler and it is correct.

---

## What changes, file by file

### Build pipeline — `Data Retrieval/extraction_tool/client_review/`

| File | Change |
|---|---|
| `build/build_database_export.py` | `MONGO_COLLECTIONS` → routed to Postgres. `_check_routing()` simplifies: nothing is double-routed when there is one destination. |
| `build/build_migrations.py` | Emit `CREATE EXTENSION vector`, an `embedding vector(1536)` column on six tables, `tsvector` columns and GIN indexes for keyword search. Delete the Mongo emitters. |
| `templates/mongo_retrieval.py` | Delete. RLS replaces it. |
| `tests/test_database_export.py` | Drop the Mongo half; add pgvector checks. The RETRIEVAL block becomes tests that RLS covers the passage tables. |
| `tests/_migration_harness.js` | Delete — it exists only to run Mongo migrations without a server. |

### Application — `DBC AI Brain/`

| File | Change |
|---|---|
| `backend/src/db/mongo.js` | **Delete.** Its whole purpose was enforcing a scope the database now enforces. |
| `backend/src/db/postgres.js` | Unchanged. `withRoles()` already covers everything. |
| `backend/src/services/retrieval.js` | New: hybrid search in SQL — `embedding <=> $1` for vectors, `ts_rank` for keyword, merged. |
| `backend/src/config/index.js` | Drop the `mongo` block. |
| `infra/docker-compose.yml` | Drop the `mongodb` service. |
| `.env.example` | Drop `MONGODB_*`; the Supabase connection strings replace them. |
| `package.json` | `db:migrate` and `db:load` lose their Mongo halves. |

### Documents

`ARCHITECTURE.md`, `DATA_MODEL.md`, `RBAC.md`, `BUILD_PLAN.md`,
`CHATBOT_PLAN.md` and `README.md` all describe two stores and need revising.

---

## Retrieval, after

Both halves become SQL, and RLS applies to both without being asked.

```sql
-- vector half
SELECT _id, text, source_file, property_key,
       embedding <=> $1 AS distance
FROM   source_documents
ORDER  BY distance
LIMIT  8;

-- keyword half
SELECT _id, text, source_file, property_key,
       ts_rank(search, plainto_tsquery($1)) AS rank
FROM   source_documents
WHERE  search @@ plainto_tsquery($1)
ORDER  BY rank DESC
LIMIT  8;
```

Neither names `allowed_roles`. Neither has to — the policy is on the table,
and `withRoles()` has already set `app.roles` for the transaction. That is
the entire argument for this change in five lines of SQL.

Merge the two with reciprocal rank fusion, as before.

---

## Order of work

1. **Stand up Supabase and load what exists today.** Do not wait for the
   rework — the 16 relational tables are unchanged, and getting a live
   database is still blocker #1.
2. Reshape `build_database_export.py` to route the ten collections to
   Postgres.
3. Extend `build_migrations.py`: the extension, the vector columns, the
   tsvector columns and their indexes.
4. Update the test suite; keep the RLS and mutation coverage.
5. Regenerate, re-verify, reload.
6. Write the embedding job — now writing to Postgres, not Mongo.
7. Delete `mongo.js`, `mongo_retrieval.py`, the harness, the Mongo service.

Steps 2–5 are the day of work. Step 1 is independent and should start now.

---

## What we lose

Atlas's managed vector infrastructure, and Mongo's schema flexibility for
passage documents. At 3,842 rows of a shape that has not changed since it was
designed, neither is worth a second database.
