# Progress log

Running record of what was done, what it changed, and what it left open.
Append at the top; never rewrite history. If something turned out to be
wrong, add an entry saying so rather than editing the old one — the mistake
and its correction are both worth keeping.

**Related:** [PLAN.md](./PLAN.md) is the current status.
[docs/BUILD_PLAN.md](./docs/BUILD_PLAN.md) is the full engineering plan.

---

## How to use this file

One entry per working session, newest first. Each entry:

```
## YYYY-MM-DD — short title

**Layer:** database | backend | frontend | rag | ingestion | ops | docs
**Status:** what moved from where to where

What was done, in a sentence or two.

**Highlights:** anything learned that changes a decision. Numbers, not
adjectives.

**Verified:** what was actually checked, and how. "Tests pass" is not a
verification; "55/55 export checks against database/" is.

**Left open:** what the next person needs to know.
```

The **Highlights** and **Verified** lines are the ones that earn their keep.
A log of "did some work" helps nobody in three months.

---

## Next up

Ordered. Take the top one.

| # | Task | Layer | Blocked by |
|---|---|---|---|
| ~~1~~ | ~~Create the Supabase project~~ **done** | ops | — |
| ~~2~~ | ~~Run migrations, load 16 tables~~ **done, 5,279 rows** | database | — |
| ~~3~~ | ~~Verify RLS on a real server~~ **done, va sees 0 economics** | database | — |
| 3b | Automate that check as a CI integration test | database | nothing |
| 4 | Decide identity — Supabase auth or Keycloak | ops | a decision |
| 5 | Decide the embedding model (1536 vs 3072) | rag | a decision |
| 6 | Consolidate: collections → tables, pgvector column | database | nothing |
| 7 | Update the export, migrations and test suite | database | 6 |
| 8 | Write and run the embedding job (3,842 rows) | rag | 5, 7 |
| 9 | Orchestrator: document questions, with citations | backend | 8 |
| 10 | Chat UI against the real endpoint | frontend | 9 |
| 11 | Eval set: ~50 questions with known answers | rag | 9 |
| 12 | Text-to-SQL with guardrails | backend | 3 |

Items 1–5 are independent of the consolidation and can start today.


---

## 2026-09-13 — The database is live. RLS tested for real, not simulated.

**Layer:** database, ops
**Status:** blocker #1 `DONE` · #2 `DONE` · #3 `DONE`

Supabase project `ihmrhwmqgsnumavebztf` (PG 17.6, ap-northeast-2). All five
migrations applied, 5,279 rows loaded in 8.9s, and the permission boundary
verified against a running server for the first time in this project.

**Verified — the numbers that were previously only simulated:**

| Role | deal_portfolio | deal_economics | hud_settlements | master_budget |
|---|---:|---:|---:|---:|
| va | 256 | **0** | **0** | **0** |
| executive | 256 | 256 | 382 | 46 |
| no role set | **0** | | | |
| empty string | **0** | | | |
| unknown role | **0** | | | |

Connecting as `ai_brain_app` over the transaction pooler — the API's own
path — RLS applies, and an INSERT is refused outright: *permission denied for
table deal_portfolio*.

**Highlights:**

- **The portable `DO` block earned itself.** `003` printed *"loader role
  postgres already bypasses RLS"*. The hard-coded
  `ALTER ROLE ai_brain_owner BYPASSRLS` it replaced would have aborted the
  migration here, on the first attempt.
- **`db.<ref>.supabase.co` is IPv6-only and this machine has no IPv6.** The
  direct host has an AAAA record and no A record, so it does not resolve at
  all. Both connections now go through the pooler: session mode (5432) for
  migrations and loading, transaction mode (6543) for the API.
- **The database password contained a `$` immediately before the `@`.** The
  scripts source `.env`, so the shell read `$@` and expanded it to nothing —
  turning the DSN into `postgres:MarylandDBC12345db.host...` with the
  separator gone. Percent-encoded to `%24`. Worth remembering for any
  credential with shell metacharacters.
- **`postgres` on Supabase is not a superuser** (`rolsuper = f`, but
  `rolbypassrls = t` and `rolcreaterole = t`). It could create `ai_brain_app`
  but not `SET ROLE` to it until granted membership. Everything the
  migrations need is available; superuser is not required.
- **The interpreter trap bit a second time**, in `load-data.sh`. Fixed the
  same way as `rebuild_all.sh` — probe for a python that can import psycopg
  rather than trusting PATH. Two scripts, same bug, because the first fix was
  local rather than systematic.

**Left open:** identity, embeddings, and the single-store consolidation. The
relational half of the database is now real and queryable.

---

## 2026-09-13 — Migrations made portable; a Supabase blocker found before it bit

**Layer:** database, ops
**Status:** `003` now runs on any host · rebuild script fixed

Audited the migrations for anything a managed host restricts, ahead of
creating the Supabase project.

**Highlights:**

- **`003_enable_rls.sql` would have failed on Supabase at line 129.** It ended
  with `ALTER ROLE ai_brain_owner BYPASSRLS;` — and `ai_brain_owner` is never
  created by any migration. It exists only because docker-compose happens to
  name the superuser that. On Supabase the owner is `postgres`, so the
  statement aborts with *role does not exist*, and with `ON_ERROR_STOP=1` the
  whole migration stops. This would have been the first error, on the first
  attempt.
- Replaced with a `DO` block that grants the exemption to `current_user`
  whatever it is called, skips if the role already has it, and — if it cannot
  — raises a warning naming the workaround (*run 001, 002, load, then
  003–005*) rather than failing silently.
- Nothing else in the migrations is restricted: no `CREATE EXTENSION`, no
  tablespaces, no `ALTER SYSTEM`, no superuser-only calls. The only version
  requirement is `security_invoker`, which needs PG 15+ — Supabase runs 15/16/17.
- **The interpreter papercut I logged yesterday cost me a build.**
  `rebuild_all.sh` called bare `python3`, which resolves to the Homebrew one
  without pandas. It now probes for an interpreter that has the dependencies
  and says which it picked. Documenting a trap is not the same as removing it.

**Verified:** 125/125 workbook, 57/57 export, 38/38 mutations. The export
suite run against `DBC AI Brain/database/` after re-syncing: 57/57. The
project copy carries the portable version — zero references to
`ai_brain_owner BYPASSRLS`.

Three new tests replace the one that asserted the old hard-coded string: the
exemption exists, it names no specific role, and it explains the workaround.

**Left open:** the consolidation, unchanged. Supabase can be created now.

---

## 2026-09-13 — Supabase chosen, and the design consolidated to one database

**Layer:** database, ops, docs
**Status:** host `DECIDED` · store count `DECIDED` · rework `NEXT`

Two decisions. **Supabase** hosts the database, and **MongoDB is removed** —
its ten collections become Postgres tables and the 3,842 embeddings go into
pgvector. Rework plan in
[docs/SINGLE_STORE_MIGRATION.md](./docs/SINGLE_STORE_MIGRATION.md).

**Highlights:**

- **The two-store design rested on one sentence — "Postgres has no vector
  search" — and Supabase ships pgvector.** When the premise goes the
  conclusion should go with it. This reverses a recommendation I argued for
  earlier in the project, and the reversal is the point: the platform
  changed, so the answer changed.
- **The data is small enough that the second database was buying nothing.**
  3,842 vectors is 22.5 MB. The whole consolidated database is 31 tables and
  10,227 rows, against a 500 MB free tier. pgvector is comfortable into the
  millions.
- **It closes the weakness recorded in every planning document so far.** With
  the passages in Postgres, the same RLS that protects deal figures protects
  them — no second permission model, no chokepoint to defend, no code path
  that can bypass it. The 3,172-of-4,948 exposure stops being a risk to
  manage.
- **Supabase has one real gotcha, and it is sharper than I first described.**
  `003` FORCEs row-level security and the only policies are `FOR SELECT` —
  there are no INSERT or UPDATE policies. So the loader does not merely see
  fewer rows without `BYPASSRLS`; its `INSERT … ON CONFLICT DO UPDATE`
  **fails outright**. Verify with `SELECT rolbypassrls FROM pg_roles WHERE
  rolname = current_user;` and if false, run 001, 002, load, then 003–005.
  `scripts/migrate.sh` now takes `--pre-rls` and `--rls-only` for exactly
  this.
- **Filtering under a vector index does not disappear, it changes direction.**
  An HNSW index is approximate, so a heavily-scoped query can return fewer
  hits than asked for. That fails *closed* — the Mongo failure mode was
  returning documents the caller may not read. At 3,842 vectors the better
  answer is to skip the index: exact search is 5.9M float ops, single-digit
  milliseconds, no recall loss.
- I also mis-framed pgvector last turn as a reason to prefer Supabase over
  self-hosted. It runs on both; Supabase only saves the `CREATE EXTENSION`.
  The hosting choice and the store-count choice are independent.

**Verified:** consolidated shape measured from the actual export — 16 + 10 +
5 = 31 tables, 10,227 rows, 3,842 rows needing a vector, 22.5 MB at 1536
dims. Policy audit confirms 16 × `FOR SELECT` and zero write policies, which
is what makes the BYPASSRLS requirement hard rather than cosmetic.

**Left open:** the rework itself — `build_database_export.py` routes ten
collections to Mongo, `build_migrations.py` emits Mongo migrations, and the
test suite covers both. About a day. Standing up Supabase does **not** wait
on it: the 16 relational tables are unchanged.

---

## 2026-09-13 — Project scaffolded, full plan written

**Layer:** docs, backend, frontend, database
**Status:** `DBC AI Brain/` created and initialized · data staged and verified

Set up the project as a workspace monorepo: `backend/` (Node + Express),
`frontend/` (React + Vite), `shared/` (constants both sides must agree on),
`database/` (schema, migrations, seed), `infra/` (docker-compose),
`scripts/`, `docs/`. Copied the database export in. Wrote the security
critical parts of the backend rather than stubbing them, and the four
planning documents.

**Highlights:**

- The export's own migration comments name the rest of the stack —
  **Keycloak** for identity ("mirrors the Keycloak subject") and **MinIO/S3**
  for files ("the bytes never enter Mongo; only the reference"). The infra
  compose file follows that rather than a guess.
- `sqlglot` is installed under `/usr/bin/python3`, not the Homebrew python
  that comes first on PATH. Running the test suites with the wrong
  interpreter fails on import. Worth knowing before someone debugs it.
- Two "failures" in my own doc verification were the regex counting prose
  about `FORCE ROW LEVEL SECURITY` inside a comment. Comments have to be
  stripped before counting SQL statements — otherwise a well-documented file
  looks like it has more statements than it does.

**Verified:**

- Export suite run **against `DBC AI Brain/database/`**, not the source:
  **55/55**.
- Copy is byte-identical to the pipeline output — SHA-256 across 46 files,
  0 differing. Only `.DS_Store` not carried over.
- MANIFEST counts match every table and collection file.
- Both loaders dry-run clean: 16 tables / 5,279 rows, 10 collections /
  4,948 documents.
- DDL declares exactly the 16 tables that have data; 15 collections created
  = 10 seeded + 5 runtime, no orphans either way.
- 21 factual claims across the docs re-checked against the data, including
  the `contract_price` averages (227,455 vs 301,042) and the Mongo exposure
  (3,172 of 4,948).
- Statements only, comments stripped: 16 × ENABLE + FORCE + POLICY + GRANT,
  7 views all `security_invoker`.

**Left open:** none of this has met a running database. Everything is
parsing and simulation, which is a lot but not the same thing. That is task
1 above.

---

## 2026-09-13 — Data request finalised, MLS list corrected

**Layer:** ingestion
**Status:** request `WIP` → sent · verification checklist `DONE`

Split the request into per-question tabs, added **MLS Listings Needed**, and
built **DBC_Verification_Checklist.xlsx** — 67 figures across 65 files, each
naming the exact file that settles it.

**Highlights:**

- **Nine "Listing" deals are brokerage, not ownership.** The CEO workbook
  keeps them on their own sheet — "Total listings: 7, profit per listing:
  2,013" — and those are commissions. 107 5th Avenue's settlement names COR
  KELLY PROPERTIES as buyer; DBC appears nowhere on it. They were being
  asked about on three tabs: purchase price, square footage and MLS listing
  for houses DBC never owned. **27 unanswerable rows removed.**
- **"81 MLS listings" was the wrong shape of question.** 97% of fix and
  flips have a listing on file; 2% of wholesales do. So of 83 missing, 3
  almost certainly exist and 64 never did. The ask went from 83 to 3 plus 7
  unknowns.
- Four of the Wholetail HUDs share a filename with a Fix and Flip file, so
  the checklist resolves paths by recorded folder first and only falls back
  to searching by name. A plain name search sends someone to the wrong copy.

**Verified:** all 60 → 65 file paths resolved against the disk. None of the
83 shares a house number and street with any of the 116 listings we hold.
None carries sqft, beds, year built or MLS number — and the control holds:
all 116 properties that *do* have a listing carry all four.

**Left open:** Dave's answers. 103 properties missing figures, 176 missing
details, 38 documents to re-send, 27 figures to confirm.

---

## 2026-09-11 — Database design reviewed end to end

**Layer:** database, rag
**Status:** export `DONE` · retrieval chokepoint added

Audited the two-store design against what the chatbot has to do, and closed
the gaps that review found.

**Highlights:**

- **`hud_settlements.sale_price` was a trap.** A HUD-1 prints "Contract
  sales price" on both the buyer's and the seller's statement, so one column
  carried both — and 228 of 382 rows are purchases. `AVG(sale_price)`
  returns **227,455** where the answer is **301,042**: understated 24%, and
  nothing about the result looks wrong. Renamed to `contract_price` at the
  export boundary, with a semantic comment and split columns on
  `v_settlements_enriched`.
- **MongoDB cannot enforce the scope.** One forgotten filter exposes 3,172
  of 4,948 documents, 1,742 of which mention profit or a five-figure sum.
  Atlas Vector Search cannot be fronted by a filtered view, because
  `$vectorSearch` must run on the collection owning the index. Added
  `retrieval.py` as a single chokepoint, and seven tests that treat it as a
  permission boundary.
- **Eight settlement prices contradicted their own listing** — Englewood
  reads 834,900 against 334,900, off by exactly 500,000; Sea Breeze 800,000
  against 300,000. OCR misreading a leading digit. Dropped and flagged.
- **The date guard on that check matters more than the check.** My first
  version compared prices alone and would have destroyed three *correct*
  prices — 4206 Henderson settled 2022-11-18 but its listing closed
  2024-07-26, a later owner's resale describing a different transaction.

**Verified:** RLS simulated across all six roles — a VA reaches 372 rows in
2 tables and no margin field. Fails closed three ways: unset, empty, unknown.

**Left open:** embeddings. The indexes are correct and the validators allow
the field; nothing populates it.

---

## 2026-09-11 — Wholesale double-close corrected

**Layer:** ingestion
**Status:** 12 pairs re-tagged · 10 sale prices recovered

A wholesale closes twice on the same day — DBC buys, then sells straight on.
Both legs arrived as `X HUD.pdf` and `X HUD 2.pdf`, and the parser read the
transaction type off the filename, so **both were purchases**. The purchase
price came from the wrong leg and the sale price we already held read as
missing.

**Highlights:** confirmed three independent ways before changing anything —
the title file number carries an `A` suffix on the second leg (232018 /
232018A on Denison), the parties differ (Edgewood's borrower is *DBC 724
EDGEWOOD, LLC* on leg 1 and *YR Realty, LLC* on leg 2), and the recorded
profit falls between zero and the spread on 9 of 9 testable pairs.

Two pairs left alone: Fairfax and Milford read the *same* file number and
the *same* price on both files, so there is no evidence of a second leg —
yet a profit is recorded. Flagged rather than guessed.

**Verified:** 45 Stockton correctly flipped from Active to Sold. Four tests
added, including one that fails if a wholesale ever sells for less than it
bought.

---

## 2026-09-11 — Test suite audited for vacuity

**Layer:** ingestion
**Status:** 86 checks → 125, plus 38 mutations

**Highlights:** **55 of 67 checks passed on a completely empty workbook.** Most
have the shape "no bad row exists", which is trivially true of no rows. The
suite could not tell a working build from a blank one.

Added population floors, and a mutation harness that breaks the data 38 ways
and asserts the suite objects. Building it found five defects in checks I had
written:

- Row-count drift compared raw tab names, covering 10 of 26 tabs — and
  missing Deal Portfolio, since the presentation renames it.
- The 1-January guard used `str(...).endswith("-01-01")`, which goes silently
  vacuous the moment pandas types the column as datetime.
- The placeholder sweep read only the frames — pandas converts `N/A`, `NULL`,
  `None`, `NaN` to NaN on read, so **5 of its 8 strings were dead letters.**
- A row missing `allowed_roles` **crashed** the export suite, taking 12 later
  checks with it.
- **The VA margin-leak check only inspected `rows[0]`.** Scope is per-row, so
  a table whose first row excludes the VA could hand them the margin on row
  two. That check is the one thing standing between a VA and every deal's
  margin, and it was a single-row sample.

**Verified:** 38/38 mutations caught.
