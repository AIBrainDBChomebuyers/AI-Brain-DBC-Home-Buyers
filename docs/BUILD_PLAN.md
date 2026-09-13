# DBC AI Brain — full build plan

The whole system, end to end: what each layer is, how it is built, and in
what order. This is the master document.

> **Superseded in part (2026-09-13).** The host is **Supabase** and the design
> is now **one database** — MongoDB is being folded into Postgres with
> pgvector. Sections 2, 4 and 8 below still describe two stores; the rework
> is specified in [SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md),
> which takes precedence where they disagree.

- [PLAN.md](../PLAN.md) — status tracking, key notes, blockers
- [SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md) — the consolidation
- [CHATBOT_PLAN.md](./CHATBOT_PLAN.md) — the website design in detail
- [ARCHITECTURE.md](./ARCHITECTURE.md) · [DATA_MODEL.md](./DATA_MODEL.md) · [RBAC.md](./RBAC.md)

---

## 0. What I am working from, and where the gaps are

Worth stating plainly, because a plan is only as good as its inputs.

| Layer | My grounding | Confidence |
|---|---|---|
| Database | I designed and built it | **Complete** |
| Ingestion | I built the extraction pipeline | **Complete** |
| RAG | Chunking, indexes and filter fields are built; §6.5 cited in code | **Partial** — retrieval mechanics known, prompt/eval design not specified |
| Backend | Stack inferred from the export (Keycloak, MinIO); I scaffolded it | **Partial** — no spec'd API contract seen |
| Frontend | MERN implies React; I scaffolded routes | **Weak** — no UX spec, no designs, no brand |
| Ops | Nothing specified anywhere I can see | **Weak** — proposals below are mine |

**The two source PDFs are not in the workspace.** They were attachments early
in the project. What survives is what the code cites: §6.5 hybrid retrieval,
§6.6, §6.7 file storage, §8, §9 roles, §10 audit, §14 embedding models. So
this plan reflects the technical document *as implemented*, plus engineering
judgement where it was silent. **Everything in §7 (frontend) and §9 (ops) is
proposal, not specification.** Read those with a pen.

---

## 1. The system

```
  Source PDFs ──► Extraction ──► JSON ──► Load ──┐
   (Data Retrieval/)      │                      ▼
                          └──► Embed ──────► Supabase Postgres
                                              facts + passages + vectors
                                                      ▲
  Browser ──► React ──► Express API ──► Orchestrator ─┤
                            │                         │
                         Keycloak                   MinIO
                        (identity)                (the PDFs)
```

Four moving parts: an extraction pipeline that runs offline, one database
holding both the facts and the passages, an API that enforces who sees what,
and a web app. Plus Keycloak for identity and MinIO for the source files.

**The one architectural decision everything else follows from:** the
permission scope lives on the data, not in the application. Every row and
every document carries `allowed_roles`. Postgres enforces it itself through
row-level security, and since the passages live there too, that one
mechanism covers everything. This is why an LLM writing its own SQL is safe
here — the worst it can do is write a useless query, not a dangerous one.

---

## 2. Database layer `DONE`

Built and verified. 55/55 checks pass against the staged export.

**PostgreSQL — 16 tables, 5,279 rows.** The facts you count. `deal_portfolio`
is the spine (256 properties); everything else foreign-keys into it. Seven
`security_invoker` views pre-join the common shapes so text-to-SQL reads one
relation instead of composing a join. RLS enabled and forced on every table.

**Passages and runtime — 15 more tables, 4,948 rows.** Ten hold data, five
are runtime (`users`, `roles`, `conversations`, `audit_logs`,
`ingested_files`). `source_documents` is the large one: 3,728 passages of
source text, 3,668 keyed to a property. Six of the ten gain an
`embedding vector(1536)` column.

These are currently emitted as MongoDB collections. Folding them into
Postgres is specified in
[SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md) — about a day, and
it is a reshape of the export, not re-extraction.

Remaining: load it into a live instance. Everything so far is static analysis
and simulation — see [PLAN.md §5](../PLAN.md).

---

## 3. Ingestion `DONE` (offline) / `TODO` (in-app)

Today: a Python pipeline outside the app reads 767 source files, resolves
them to 256 properties, and emits the JSON the database loads. Run by hand
with `rebuild_all.sh`, then `npm run db:sync && npm run db:load`.

**What it does that matters downstream:**

- **Two-pass OCR** — flat text, plus word coordinates, because HUD-1s are
  two-column and flat text tears the rows apart.
- **Content-hash dedupe** — 16 byte-identical duplicates dropped, not lost.
- **Entity resolution** to a stable `property_key`, which is the only reason
  a settlement, a listing, a budget and a loan statement can be recognised as
  the same house.
- **Source-precedence reconciliation** — when four documents disagree about a
  price, `deal_portfolio` holds the reconciled figure and the child tables
  hold what each document actually said. Provenance columns
  (`profit_source`, `sold_date_source`, `property_location_source`) record
  which won.

**To build (M4):** upload → MinIO → queue → re-extract → re-embed → reload,
without anyone running a script. The loaders are already idempotent, which is
what makes this cheap.

---

## 4. RAG layer `BLOCKED`

The blocking item for the whole product. Everything is in place except the
embeddings themselves.

### 4.1 What exists

| Piece | State |
|---|---|
| Chunking | Done — 1,200 chars, 150 overlap, at extraction time |
| Collections to embed | Done — 6 marked `embedded` in `schema.json` |
| Vector indexes | Declared — 1536d, cosine, `allowed_roles`/`sensitivity`/`property_key` as filter fields |
| Keyword indexes | Done — one `$text` index per embedded collection |
| Scoped retrieval | Done — `backend/src/db/mongo.js`, `database/mongodb/retrieval.py` |
| **Embeddings** | **Nothing generates them** |

Why 1,200/150: large enough that a fact is not split across chunks, small
enough that a retrieved passage is mostly signal. The 150-char overlap means
a figure sitting on a boundary survives whole in one of the two.

### 4.2 The embedding job — write this first

A script, not a service. Roughly:

```
for each of the 6 embedded collections:
    for each document missing `embedding`:
        vector = embed(document.text)      # batch ~100 at a time
        write vector back to the document
```

Requirements that are easy to get wrong:

- **Resumable.** 3,728 passages is one long run; it will be interrupted.
  Query for `embedding: null` so a re-run picks up where it stopped.
- **Batched.** One API call per passage is slow and expensive.
- **Dimension-locked.** The index declares 1536. A model producing anything
  else fails at query time, not write time, which is a bad place to find out.
- **Idempotent**, like everything else in this project.

Then create the Atlas vector indexes — they can only be created once the
field exists, which is why `002_create_indexes.js` says so in a comment.

### 4.3 Retrieval

Hybrid, per §6.5:

**Vector.** `$vectorSearch` with `allowed_roles` as a filter *inside* the
search. This is not a detail. Filtering afterwards picks the top-k from
documents the caller may not read and then discards them — the answer
silently loses recall, and there is no error to notice.

**Keyword.** `$text` on the same collections, for what embeddings blur: a
file number, a lender's name, an exact address.

**Merge.** Dedupe on `_id`, combine scores (reciprocal rank fusion is the
simple default), take the top 5–8.

### 4.4 Text-to-SQL

The other half of retrieval, and the reason for Postgres.

**Context given to the model:** the schema, plus the column comments —
`column_catalog` (291 documents) exists for exactly this, and
`005_add_comments.sql` writes coverage notes into the database so
`information_schema` carries them.

**Two traps the prompt must name explicitly:**

1. `hud_settlements.contract_price` is a **purchase** price on 228 of 382
   rows. `AVG(contract_price)` returns 227,455 where the answer is 301,042.
   Use `v_settlements_enriched`, which splits it, or group by
   `transaction_type`.
2. Sparse columns carry `populated on N of M rows`. Averaging a 59%-filled
   column without saying so produces a confident, wrong number.

**Guardrails:** parse the generated SQL and reject anything that is not a
single `SELECT`; statement timeout; row cap; execute inside `withRoles()` so
RLS applies; log the SQL with the answer.

### 4.5 Generation and citation

Answer **only** from what retrieval returned. If nothing came back, say so.

The worst failure this product can have is a plausible number with no source.
The business would act on it and nothing in the interface would suggest it
was invented. Every factual claim carries its origin — document and page for
a passage, table and property for a figure — and a citation is a link that
opens the PDF.

### 4.6 Evaluation — build this alongside, not after

A retrieval system without an eval set is a system nobody can improve,
because every change is a guess.

Start with ~50 questions whose answers we already know from the workbooks:
*"What did 4216 Berger sell for?"* → 83,500. *"How many properties did we
sell in 2024?"* Score retrieval (did the right passage come back in the top
5?) separately from generation (was the answer right?), because they fail for
different reasons and the fixes are different.

---

## 5. Backend `WIP`

Node 20 + Express, ES modules. Scaffolded; the security-critical parts are
written, the orchestrator is a stub.

### 5.1 Structure

```
backend/src/
  config/       one place that reads the environment
  db/           postgres.js, mongo.js  ← the permission boundary
  middleware/   auth.js, audit.js, errors.js
  routes/       health, properties, chat, documents, admin
  services/     orchestrator, retrieval, text-to-sql, embeddings
  utils/
```

### 5.2 The two files that matter

**`db/postgres.js`.** `withRoles(roles, fn)` opens a transaction, sets
`app.roles` with `SET LOCAL`, runs the query, commits. `SET LOCAL` rather
than `SET` because the pool shares connections and a session-level setting
would leak the previous user's roles to the next request — a bug that does
not show up in testing and is catastrophic in production.

**`db/mongo.js`.** `scopedFind`, `scopedAggregate`, `vectorSearch`,
`keywordSearch`. Each takes roles as a required argument and refuses an empty
or unknown list rather than returning nothing — a caller with no roles has a
bug, and a query that silently returns zero rows is that bug reaching
production disguised as an empty dataset. `scopedAggregate` prepends the
`$match`, never appends: an accumulator over rows the caller cannot read
leaks the answer even when the rows are dropped afterwards.

### 5.3 To build

| Service | Job |
|---|---|
| `orchestrator` | classify → retrieve → generate → cite → record |
| `retrieval` | hybrid search, merge, rerank |
| `textToSql` | generate, validate, execute, format |
| `embeddings` | the batch job, and on-demand for new uploads |
| `documents` | signed MinIO URLs, scope-checked |
| `conversations` | history, and reading it back as memory |

### 5.4 Testing

- **Unit** — scope helpers, SQL validation, merge logic.
- **Integration** — against a real Postgres in a CI container. This is where
  RLS gets tested for real, which has not happened yet.
- **Permission tests, one per role.** For each of the six, assert what is
  visible and what is not — particularly that a VA reaches no margin field.
  This is the suite that must never be skipped.

---

## 6. Frontend `WIP`

React 18 + Vite, scaffolded to routes and an API client. **No UX
specification exists that I can see, so what follows is proposal.**

### 6.1 Pages

Chat and Properties first; the rest can wait.

| Page | Purpose |
|---|---|
| `/chat` | The product |
| `/chat/:id` | A past thread |
| `/properties` | Browse and filter |
| `/properties/:key` | One house, everything about it |
| `/documents` | What we hold |
| `/upload` | Add documents |
| `/admin` | Users, roles, audit — executive only |

### 6.2 Three decisions worth making before writing components

**Show the working.** Under each answer: the documents used, and the SQL if
any ran. Collapsed by default. Trust in this product gets built by people
checking it and finding it right.

**Distinguish three empty states.** They look identical and only one is true:

- *We hold nothing on this* — 83 properties have no MLS listing
- *You are not permitted to see this* — restricted to another role
- *We hold the document but cannot read it* — 38 such PDFs

**Show coverage honestly.** Purchase date is on 86% of sold properties, sale
price 76%, square footage 59%. An average over 59% of the portfolio should
say so on the face of it.

### 6.3 Auth flow

`keycloak-js` → PKCE → token in memory (not localStorage) → attached to every
request by `api/client.js`. Roles are read from the token for **display only**
— to hide a nav item the user cannot use. Every real decision is made
server-side, because a client that decides its own permissions has none.

---

## 7. Infrastructure `TODO`

Nothing here is specified; all proposal.

**Local:** `infra/docker-compose.yml` brings up Postgres (the
`pgvector/pgvector:pg16` image), Keycloak and MinIO. Close enough to Supabase
for everything except its role setup — verify anything touching `BYPASSRLS`
against the real project.

**Environments:** local → staging → production. Staging matters more than
usual here because RLS behaviour and vector search are both things that
cannot be fully checked locally.

**Secrets:** never in the repo. `.env.example` documents the shape; the real
values come from the platform's secret store.

**Backups:** Supabase handles them. The source PDFs in MinIO are the actual
irreplaceable asset — everything else can be rebuilt from them by re-running
the pipeline.

**Monitoring:** answer latency split by path (SQL vs vector), retrieval
quality against the eval set, audit volume by role, and error rate on
generated SQL.

---

## 8. Security

The model end to end, since it spans every layer:

1. **Identity** — Keycloak. Roles come from the verified token and nowhere
   else: never a header, never a body.
2. **Postgres** — RLS enabled and forced on all 16 tables. Fails closed three
   ways: unset, empty, or unknown roles all yield zero rows. The app role
   holds `SELECT` and nothing else. All views are `security_invoker`.
3. **Passages** — under the same RLS as everything else, once folded in.
   This removes what was the sharpest edge in the system: while they sat in
   MongoDB the scope was enforced by application code, and one forgotten
   filter exposed 3,172 of 4,948 documents.
4. **Generated SQL** — `SELECT`-only, parsed before execution, run as a role
   with no write grant.
5. **Files** — MinIO, signed URLs, scope checked against the property before
   the URL is issued.
6. **Audit** — append-only; insert and find granted, never update or delete.
   An audit trail the application can edit is not one.

---

## 9. Build sequence

Each milestone is usable on its own. No phase where the site exists but does
nothing.

### M0 — Foundations `NEXT`
Supabase project created, migrations run for real, the 16 existing tables
loaded. **Integration tests proving RLS behaves as simulated** — the first
time that claim gets tested rather than reasoned about. Identity decided
(Supabase auth or Keycloak) and set up.

Do not wait for the consolidation: the relational tables are unchanged, and a
live database is still the top blocker.

### M1 — It answers something
Consolidation done (collections → tables, pgvector column). Embedding job
written and run over 3,842 rows. Chat answers document questions with
citations. *The first point at which the thing is real.*

### M2 — It answers with numbers
Text-to-SQL with guardrails. Both retrieval paths merged. Properties list and
detail, mostly a thin layer over `v_deal_full`. Eval set built.

### M3 — It remembers
Conversation history. Follow-ups that resolve against the previous turn.

### M4 — It grows
Upload → MinIO → re-extract → re-embed → reload, no manual step. Closes the
loop that currently needs someone to remember `rebuild_all.sh`.

### M5 — It is operable
Admin: users, roles, audit browsing. Monitoring. CI on every change.

---

## 10. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| ~~Mongo scope forgotten~~ | *Removed by consolidating* — RLS now covers passages | — |
| **Vector search under RLS under-returns** | Approximate index + filter can yield too few hits | Fails closed, not open. Use exact search at this scale |
| **Confident wrong answers** | The business acts on them; nothing looks wrong | Cite everything; say "I don't know"; eval set |
| **Text-to-SQL misreads a trap column** | 24% error on a question anyone would ask | Schema comments; prefer views; log the SQL |
| **Thin coverage read as fact** | Averages over 59% of the portfolio | Surface coverage in the answer |
| **Embedding model changed later** | Re-embed everything, rebuild the index | Decide before M1 — see below |
| **Data leaves the cloud unnoticed** | The audit schema implies someone cares | Decide the policy before M1 |

---

## 11. Decisions needed before M1

1. **Embedding model.** §14 recommends `text-embedding-3-large` (3072d); the
   export is built for `text-embedding-3-small` (1536d) and the index is
   declared at that size. Changing after embedding means redoing all of it.
2. **Does data leave our cloud?** A hosted model sends the question and the
   retrieved passages out. Self-hosted (`bge-large-en-v1.5`,
   `nomic-embed-text`) keeps them in. Policy, not engineering — and the audit
   schema's `left_our_cloud` field suggests it has already been thought about.
3. **Generation model.** Separate from the embedding choice, same question
   about where the text goes.
4. **Who can upload.** Ingestion changes what everyone else sees.
5. **Refresh cadence.** Nightly, or on upload.
