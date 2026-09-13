# The chatbot website — plan

What we are building on top of the data layer: an internal web app where
someone at DBC asks a question in plain English and gets an answer drawn from
the company's own records, with the document it came from, and only from the
parts they are allowed to see.

Status tracking lives in [../PLAN.md](../PLAN.md). This file is the design:
what the site is, how an answer is produced, and the order to build it in.

> **Note (2026-09-13).** Retrieval below is described against MongoDB. The
> design has since consolidated to one Postgres database with pgvector — the
> pipeline is unchanged in shape, but both halves become SQL and RLS applies
> to the passages too. See [SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md).

---

## 1. Who uses it, and what changes for them

Six roles, and the site is not the same product for each. A VA reaches 372
rows across 2 tables; an executive reaches 5,279 across 16. That is not a
feature flag — it is row-level security in the database, and the interface
has to make it legible rather than confusing.

| Role | Typical question |
|---|---|
| Executive | "Which county gave us the best margin last year?" |
| Acquisitions | "What did we pay for comparable houses in 21229?" |
| Construction | "How long did the Rickey renovation take, and who ran it?" |
| Property management | "What is the cash in the deal on Aldeney?" |
| Accounting | "What did Kiavi charge us in interest on Bullneck?" |
| VA | "What is the address and ZIP for the Odell property?" |

**The design consequence:** when a question touches data the asker cannot
see, the answer must say so — *"that figure is restricted to accounting"* —
rather than returning nothing and letting them conclude the data is missing.
Silence and absence look identical, and only one is true.

---

## 2. Pages

| Page | Route | Purpose |
|---|---|---|
| Chat | `/chat` | The product. Ask, read, follow the citation. |
| Conversation history | `/chat/:id` | Reopen a past thread. Phase 2 reads it back as memory. |
| Properties | `/properties` | Browse and filter the portfolio; the answer to "just show me the list". |
| Property detail | `/properties/:key` | One house: figures, documents, loans, construction, timeline. |
| Documents | `/documents` | What we hold, by property. Opens the source PDF. |
| Upload | `/upload` | Add documents; triggers re-extraction. |
| Admin | `/admin` | Users, roles, audit trail. Executive only. |

Chat and Properties are the two that matter. Everything else can wait.

---

## 3. How an answer is produced

    question
       │
       ├─ 1. classify ──► figures? documents? both?
       │
       ├─ 2. retrieve
       │      ├─ Postgres  text-to-SQL over the schema + column comments
       │      └─ Mongo     vector + keyword, merged
       │
       ├─ 3. generate ──► answer, grounded only in what came back
       │
       ├─ 4. cite ──────► which document, which row
       │
       └─ 5. record ────► audit_logs: who, what, whether it left our cloud

### 1. Classify

Three kinds of question, and they route differently:

- **Figures** — "average profit by county" → SQL. Exact, aggregatable.
- **Documents** — "what did the seller agree to" → vector search. Language.
- **Both** — "what did we make on Hobbit, and what does the settlement say?"

Getting this wrong is recoverable (run both, cost is latency) so start by
running both and only optimise once we can see real questions.

### 2a. Text-to-SQL

The model is given the schema and the column comments as context — that is
what `column_catalog` (291 documents) is for, and why `005_add_comments.sql`
writes coverage notes into the database itself.

Two things it must be told, because the data has traps:

- `hud_settlements.contract_price` is a **purchase** price on 228 of 382
  rows. Never aggregate without `transaction_type`. Prefer
  `v_settlements_enriched`, which splits it.
- Sparse columns carry a `populated on N of M rows` comment. Averaging a
  2%-filled column produces a confident, wrong number.

Generated SQL runs as `ai_brain_app`, which holds `SELECT` and nothing else,
inside a transaction with `app.roles` set. A careless query is therefore
limited to being useless, not dangerous.

**Guardrails:** statement timeout, row cap, `SELECT`-only parse check before
execution, and the SQL logged with the answer so a wrong number is
diagnosable.

### 2b. Retrieval over documents

Hybrid, per §6.5:

- **Vector** — `$vectorSearch` over the six embedded collections, 1536d,
  `allowed_roles` declared as a filter field so the scope applies *inside*
  the search. Passages are 1,200 characters with 150 overlap.
- **Keyword** — the `$text` index on the same collections, for exact matches
  the embedding blurs: a file number, an address, a lender's name.

Merge, dedupe by `_id`, rerank, take the top few. 3,668 of 3,728 passages
carry a `property_key`, so a passage can be tied back to the house it
describes and joined to the figures.

### 3. Generate

Answer only from what retrieval returned. **If nothing came back, say so.**
The single worst failure mode for this product is a plausible number with no
source — the business would act on it, and nothing in the interface would
suggest it was invented.

### 4. Cite

Every factual claim names its origin: the document and page for a passage,
the table and property for a figure. A citation is a link that opens the PDF.

This is not a nicety. The whole reason the extraction records
`source_file`, `property_location_source`, `profit_source` and the rest is so
an answer can be checked without trusting it.

### 5. Record

`audit_logs` is append-only — insert and find granted, never update or
delete. One field per bullet in §10, including which collections were
retrieved, which SQL ran, and whether the question left our cloud.

---

## 4. API surface

    GET  /api/health                     open; readiness probe
    POST /api/chat                       ask; returns answer + citations
    GET  /api/chat/conversations         list mine
    GET  /api/chat/conversations/:id     one thread
    GET  /api/properties                 filter, paginate
    GET  /api/properties/:key            one property, joined
    GET  /api/properties/:key/documents  what we hold
    GET  /api/documents/:id/download     signed MinIO URL, scope checked
    POST /api/documents                  upload; queues re-extraction
    GET  /api/admin/audit                executive only

Every route below `/health` requires a verified Keycloak token. Roles come
from the token and nowhere else.

---

## 5. Interface decisions worth making early

**Show the working.** Under each answer: the documents used, and the SQL if
any ran. Collapsed by default. Trust in this product will be built by people
checking it and finding it right.

**Distinguish "no data" from "not permitted" from "we do not know".** Three
different states that all look like an empty answer:

- *We hold nothing on this* — 83 properties have no MLS listing.
- *You cannot see this* — restricted to another role.
- *The document is unreadable* — 38 PDFs we hold but cannot read a price off.

**Surface confidence honestly.** Coverage is uneven: purchase date is on 86%
of sold properties, sale price on 76%, square footage on 59%. An average
computed over 59% of the portfolio should say so.

**Make the citation the primary affordance,** not a footnote. The question
behind most questions is "where did that come from?"

---

## 6. Build order

Each milestone should be usable on its own — no phase where the site exists
but does nothing.

### M1 — It answers something `NEXT`
Live database, Keycloak realm, embeddings generated. Chat answers
document questions only, with citations. No SQL yet. **This is the first
point at which the thing is real.**

### M2 — It answers with numbers
Text-to-SQL over the schema, with guardrails. Both paths merged. The
properties list and detail pages, which are mostly a thin layer over
`v_deal_full`.

### M3 — It remembers
Conversation history, follow-up questions that resolve pronouns against the
previous turn, saved threads.

### M4 — It grows
Upload to MinIO, re-extraction triggered, new documents searchable without a
manual pipeline run. This closes the loop that currently requires someone to
run `rebuild_all.sh` by hand.

### M5 — It is operable
Admin: users, roles, audit browsing. Monitoring on retrieval quality and
latency. CI running the three suites.

---

## 7. Open questions

Answering these changes the build, so they are worth asking before M2.

1. **Which embedding model?** §14 recommends `text-embedding-3-large` (3072
   dimensions); the export is built for `text-embedding-3-small` (1536), which
   is cheaper and the index is already declared at that size. Changing later
   means re-embedding everything and rebuilding the index.
2. **Does data leave our cloud?** The audit schema has a `left_our_cloud`
   field, which implies the answer is sometimes yes and that it matters.
   A hosted model sends the question and the retrieved passages out; a
   self-hosted embedding model (`bge-large-en-v1.5`, `nomic-embed-text`) keeps
   the text in. This is a policy decision, not a technical one.
3. **Who can upload?** Ingestion changes what everyone else sees.
4. **How current must it be?** Nightly re-extraction, or on upload?
5. **Does the VA scope hold up in practice?** 372 rows across 2 tables is a
   narrow view. Correct per §9, but worth checking against what a VA is
   actually asked to do.

---

## 8. What I am working from

Grounded in artifacts I can read: the data layer as built, and the sections
of the technical document its code cites — §6.5 hybrid retrieval, §6.7 file
storage, §9 the role table, §10 audit fields, §14 embedding models.

I do **not** currently have the two source PDFs in the workspace; they were
attachments earlier in the project. So the plan above reflects the technical
document as it was implemented, not necessarily as it is written today.
Worth a pass against the current version before M2 — particularly §8, which
the code references once but which I cannot see.
