# Data model

`property_key` is the join. It is a normalised short form of the address
("144 hobbit"), stable across every source, and it is what lets a settlement,
a listing, a budget and a loan statement all be recognised as the same house.

## PostgreSQL — what you count

`deal_portfolio` is the spine: one row per property, 256 of them, with the
resolved purchase and sale figures. Everything else has a foreign key into
it, which is why the loader writes it first.

Resolution matters here. A property's purchase price may appear in a
settlement, a listing, the accounts and a cash sheet, and they do not always
agree. `deal_portfolio` holds the reconciled figure and the child tables hold
what each document actually said. When they differ, the portfolio is the
answer and the child table is the evidence.

`deal_economics` is split off deliberately: it carries profit, margin and
cash-in, and it is the table a VA cannot read.

**One naming trap, and it is signposted in the schema comments.** A HUD-1
prints "Contract sales price" on line 101 of the buyer's statement and line
401 of the seller's, so the extraction carries a single price column. In the
database it is `hud_settlements.contract_price`, not `sale_price`, because
228 of the 382 rows are PURCHASES. `AVG(contract_price)` across the table
blends both sides and understates the sale figure by 24%. Group or filter on
`transaction_type`, or use `v_settlements_enriched`, which splits it into
`purchase_price` and `sale_price` for you.

## The passage tables — what you search

> Formerly MongoDB collections; being folded into Postgres as tables with an
> `embedding vector(1536)` column. See
> [SINGLE_STORE_MIGRATION.md](./SINGLE_STORE_MIGRATION.md).

`source_documents` holds every passage of every source PDF, chunked, each
carrying the `property_key` it belongs to and the file it came from. That is
what makes a citation possible.

The rest are small and are fetched whole rather than searched:
`headline_kpis`, `ceo_briefing`, `glossary`, `column_catalog` (which is what
gets handed to the text-to-SQL prompt as schema context), `file_index`.

Five runtime collections are created empty by the migrations: `users`,
`roles`, `conversations`, `audit_logs`, `ingested_files`.

## Provenance

Most tables carry a `*_source` column beside a resolved value -
`sold_date_source`, `profit_source`, `property_location_source`. They record
which document a figure came from, which is what makes a disagreement
diagnosable rather than mysterious.
