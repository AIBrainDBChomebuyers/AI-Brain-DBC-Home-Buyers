# DBC AI Brain — plan and status

Living document. Update it in the same commit as the work it describes; a
plan that lags the code is worse than none, because people trust it.

Day-to-day working notes go in [PROGRESS.md](./PROGRESS.md); the full
engineering plan is [docs/BUILD_PLAN.md](./docs/BUILD_PLAN.md).

**Status keys:** `DONE` shipped and verified · `WIP` in progress ·
`NEXT` ready to start, nothing blocking · `BLOCKED` waiting on something
named · `TODO` not started · `N/A` decided against

---

## 1. At a glance

| Area | Status | Note |
|---|---|---|
| Source extraction | `DONE` | 767 files read, 0 failures |
| Data reconciliation | `WIP` | 67 figures out with Dave for confirmation |
| Database schema | `WIP` | 16 tables live; 10 collections to fold in — see [SINGLE_STORE_MIGRATION](docs/SINGLE_STORE_MIGRATION.md) |
| Seed data | `DONE` | 5,279 rows + 4,948 documents, staged and loadable |
| Host | `DONE` | **Supabase** decided 2026-09-13 |
| Store count | `WIP` | **One database** decided 2026-09-13; rework pending |
| Access control | `DONE` | RLS on all tables; extends to passages once folded in |
| Project scaffold | `DONE` | backend / frontend / shared / database / infra |
| Live database | `DONE` | Supabase, PG 17.6, 5,279 rows, RLS verified 2026-09-13 |
| Embeddings | `BLOCKED` | nothing generates them — see §5 |
| Orchestrator | `TODO` | stub in place, seam defined |
| Identity (Keycloak) | `TODO` | container runs, realm not created |
| Frontend | `WIP` | routes and API client only |

---

## 2. Phases

### Phase 0 — Extraction `DONE`

- [x] Read every source document — 769 on disk, 767 indexed, 2 excluded with cause
- [x] All 398 HUD settlements across Fix and Flip, Wholesale, Wholetail
- [x] Content-hash deduplication (16 exact duplicates dropped, not lost)
- [x] Two-pass OCR: flat text plus word coordinates for two-column HUD-1s
- [x] Entity resolution to a stable `property_key`

### Phase 1 — Reconciliation `WIP`

- [x] 256 properties resolved across every source
- [x] Wholesale double-close corrected (12 pairs; 10 sale prices recovered)
- [x] 8 settlement prices the listing disproves — dropped and flagged
- [x] Verification checklist built: 67 figures, 65 files, every path resolved
- [ ] **Dave's answers received and folded back in** — sent, awaiting reply
- [ ] Re-run extraction once his documents arrive

### Phase 2 — Database `DONE` (staged) / `BLOCKED` (live)

- [x] Two-store split decided and justified — see `docs/ARCHITECTURE.md`
- [x] Postgres: 16 tables, FKs, GIN indexes, 7 `security_invoker` views
- [x] RLS enabled and forced, policies fail closed three ways
- [x] Mongo: 10 data + 5 runtime collections, validators, text and vector indexes
- [x] Idempotent loaders for both, in FK order
- [x] Rollbacks for every migration
- [ ] **Load into a running Postgres and Mongo** — never done; no instance yet
- [ ] Confirm RLS behaves as simulated against a real server

### Phase 3 — Retrieval `BLOCKED`

- [x] Vector indexes declared: 1536d, `text-embedding-3-small`, `allowed_roles` as filter
- [x] Scoped retrieval helpers (`backend/src/db/mongo.js`, `database/mongodb/retrieval.py`)
- [ ] **Generate embeddings** — the blocking item for everything below
- [ ] Hybrid retrieval: vector + keyword, merged and reranked
- [ ] Text-to-SQL over the Postgres schema, using the column comments as context
- [ ] Citation: every answer names the document it came from

### Phase 4 — Application `TODO`

Designed in [docs/CHATBOT_PLAN.md](docs/CHATBOT_PLAN.md) — pages, the answer
pipeline, API surface and the five milestones. Read it before starting M1.


- [x] Scaffold: workspaces, config, error handling, health check
- [x] Auth middleware against Keycloak JWKS
- [x] Audit middleware, append-only
- [ ] Keycloak realm, client and the six roles
- [ ] Orchestrator: classify → retrieve → generate → record
- [ ] Conversation history (`conversations` collection is created and empty)
- [ ] Frontend: real chat, citations, property detail
- [ ] Document upload → MinIO → re-extraction

### Phase 5 — Operations `TODO`

- [ ] CI: run the three suites on every change
- [ ] Deployment target chosen
- [ ] Backups for both stores
- [ ] Monitoring: query latency, retrieval quality, audit volume

---

## 3. Key notes

What we learned that changed the design. Newest first.

**The HUD price column is a trap in a database.** A HUD-1 prints "Contract
sales price" on both the buyer's and the seller's statement, so the
extraction carried one column named after the form. 228 of 382 rows are
purchases. `AVG(sale_price)` returns 227,455 where the answer is 301,042 —
understated 24%, and nothing about the result looks wrong. Renamed to
`contract_price` at the export boundary, with a semantic comment and split
columns on `v_settlements_enriched`.

**MongoDB cannot enforce the permission scope.** Postgres refuses rows
through RLS; Mongo returns whatever is asked for. One forgotten filter
exposes 3,172 of 4,946 documents, 1,742 mentioning profit or a five-figure
sum. Atlas Vector Search cannot be fronted by a filtered view either, because
`$vectorSearch` must run on the collection owning the index. Mitigated with a
single chokepoint, not a policy. **This remains the sharpest edge in the
system.**

**Wholesale deals close twice on the same day.** Both legs arrived named
`X HUD.pdf` and `X HUD 2.pdf`, and the parser called both purchases — so the
purchase price came from the wrong leg and the sale price we held read as
missing. Confirmed three ways (title file number `A` suffix, parties on the
page, profit falling between zero and the spread on 9 of 9). 12 pairs fixed.

**Listing deals are brokerage, not ownership.** Nine "Listing" properties
were being asked about across three tabs — purchase price, square footage,
MLS listing — for houses DBC never owned. 107 5th Avenue's settlement names
COR KELLY PROPERTIES as buyer; DBC appears nowhere. Removed, 27 rows of
unanswerable questions.

**Asking for "81 MLS listings" was the wrong shape.** 97% of fix and flips
have a listing; 2% of wholesales do. So of 83 missing, 3 almost certainly
exist and 64 never did. The ask went from 83 to 3 plus 7 unknowns.

**55 of 67 workbook checks passed on an empty workbook.** Most checks are
"no bad row exists", which is true of no rows. Added population floors and a
mutation suite that breaks the data 38 ways and asserts the suite objects.

**A "wrong document" is usually a scanning failure.** 28 files flagged as
the wrong document had the price on the page under a label the reader did not
know (`Sale Price of Froperty`, HUD-1 line 700's `based on price`). Recovered
18; the fallback runs only where the primary reader draws a blank, because as
an equal voter it moved five already-correct prices.

---

## 4. What is proven, and how

Claims here are measured, not assumed. Re-run these before trusting them.

| Claim | Evidence | Last run |
|---|---|---|
| Every source file extracted | 769 on disk, 767 indexed, 2 excluded with cause | 2026-09-13 |
| Seed data is complete and valid | export suite, 55/55, run against `database/` | 2026-09-13 |
| The copy matches the pipeline | SHA-256 over 46 files, 0 differing | 2026-09-13 |
| Manifest matches the files | every table and collection count | 2026-09-13 |
| Both loaders can read it | dry run: 16 tables/5,279 rows, 10 colls/4,948 docs | 2026-09-13 |
| DDL and data agree | 16 declared, 16 with data, no orphans either way | 2026-09-13 |
| RLS fails closed | simulated: unset, empty and unknown roles all yield 0 rows | 2026-09-13 |
| A VA sees no margin field | simulated across all 16 tables | 2026-09-13 |
| Workbooks are correct | 125 checks | 2026-09-13 |
| The checks themselves work | 38 mutations, all caught | 2026-09-13 |

**Not proven:** everything above is static analysis and simulation. No
migration has run against a real PostgreSQL, and no query has been executed
against real RLS. That is the first task of Phase 2's remaining item.

---

## 5. Blockers

**No embeddings.** Nothing populates the `embedding` field. The indexes are
correct and the validators allow it, so this is a script to write, not a
design problem — read the six embedded collections, call
`text-embedding-3-small`, write the vector back. Until it runs, semantic
search returns nothing and Phase 3 cannot start. *Owner: unassigned.*

**No running database.** The schema and data have never met a live server.
Everything is verified by parsing and simulation, which catches a great deal
but not, for instance, a policy that parses and behaves differently than
expected. Needs Docker or a hosted instance. *Owner: unassigned.*

**Waiting on Dave.** 103 properties missing purchase or sale figures, 176
missing property details, 38 documents to re-send, 27 figures to confirm.
The system works without them; the answers are just thinner. *Sent
2026-09-13.*

---

## 6. Decisions

| Decision | Why | Revisit if |
|---|---|---|
| **One database, Supabase** | pgvector removed the reason for two. 3,842 vectors is 22.5 MB | Corpus grows 100x |
| ~~Postgres **and** Mongo~~ | *Reversed 2026-09-13.* Justified by "Postgres has no vector search"; Supabase ships pgvector | — |
| Postgres over MySQL | Row-level security | MySQL ships equivalent RLS |
| Scope enforced in the database, not the app | An app forgets; a policy cannot | — |
| `deal_economics` split from `deal_portfolio` | So a VA can read a property without reading its margin | Role definitions change |
| Seed data committed | A fresh environment must load without running the pipeline | It grows past a sensible repo size |
| Extraction stays outside the app | It works, and moving it buys nothing today | It needs to run on a schedule |
