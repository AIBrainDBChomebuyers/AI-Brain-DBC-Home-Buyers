# Architecture

**One database: Supabase Postgres.** Decided 2026-09-13 — see
[SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md) for the reasoning
and the rework plan. Earlier revisions of this file described a Postgres +
MongoDB split; that is superseded.

## The shape of a question

    browser ──► API ──► classify ──┬──► SQL over the deal tables
                                   └──► SQL over the passage tables
                                          (vector + keyword)
                                          │
                                       generate ──► answer + citation
                                          │
                                       audit_logs

Both retrieval paths are SQL against the same database, under the same
row-level security. That is the whole point of the consolidation.

## Why one database

The original design put deal figures in Postgres and passages in MongoDB,
because "what is the average profit by county" is arithmetic over rows and
"what did the seller agree to" is similarity over language, and Postgres had
no vector search.

Supabase ships pgvector, so it does. And the corpus is 3,842 passages — 22.5
MB of vectors, which pgvector handles without noticing. A second database
bought nothing except a second permission model.

**The deciding factor remains row-level security.** It is why Postgres over
MySQL, and now it is also why Postgres over Postgres-plus-Mongo: the
permission boundary is enforced by the database, so neither a careless
text-to-SQL query nor a forgotten filter in retrieval code can read a row the
user may not see.

## The permission boundary

`allowed_roles` is on every row, in all 31 tables — deal figures, document
passages and runtime records alike.

RLS enabled and **forced** on every table, one read policy each:

    string_to_array(current_setting('app.roles', true), ',') && allowed_roles

The API sets `app.roles` per transaction with `SET LOCAL`, never plain `SET` —
the pool shares connections, and a session-level setting would leak the last
user's roles to the next request. This is also what makes Supabase's
transaction-mode pooler safe to use.

The application role holds `SELECT` and nothing else. All views are
`security_invoker`, so none can be used to read around a policy.

Three ways a request can arrive without a usable scope, and all three return
nothing rather than everything: unset (`current_setting` → NULL → overlap →
NULL → excluded), empty string (`{''}` overlaps nothing), unknown role (no
row lists it).

## Vector search under RLS

An HNSW index is approximate: Postgres walks the index, then applies the RLS
predicate, so a heavily-scoped query can return **fewer** results than asked
for. Worth knowing, but note the direction — it fails closed. Too few
results is a recall complaint; the alternative design's failure mode was
returning documents the caller may not read.

**At this scale the mitigation is to skip the index.** Exact search over
3,842 vectors is 5.9M float operations — single-digit milliseconds, no
approximation, no tuning. Build HNSW when the corpus is ten times larger.

## Known gaps

**Embeddings are not generated.** Nothing populates the vector column. This
is the single blocking item for the retrieval half. 3,842 rows across six
tables.

**The consolidation is planned, not done.** The export still emits ten Mongo
collections. Steps and file-by-file changes are in
[SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md).

**The orchestrator is a stub.** `backend/src/services/orchestrator.js`
returns a placeholder. The seam exists so the rest can be built around it.

**Identity is undecided.** Supabase ships auth, and the design assumes
Keycloak. Running both is redundant; pick one before wiring it up.
