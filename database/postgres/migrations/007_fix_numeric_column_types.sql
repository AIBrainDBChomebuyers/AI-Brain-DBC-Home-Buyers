-- 007  Two numeric columns had reached Postgres as TEXT
--
-- Hand-written, not generated. 001-005 come from build_migrations.py; this is
-- a fix-up for a database that is already loaded. A database built from 001
-- today already has both columns as NUMERIC.
--
-- Both were wrong for the same reason. Column types come from the workbook's
-- Column Map, looked up by name, with `types.get(name, "text")` as the
-- fallback. Two columns are not in that map and so took the fallback:
--
--   deal_economics.profit_ballpark   invented by the export, so it was never
--                                    in the Column Map at all
--   hud_settlements.contract_price   renamed from sale_price AFTER the map was
--                                    consulted, so the lookup missed. sale_price
--                                    is declared `number`; the rename lost it.
--
-- Nothing failed. The rows loaded, the values look right in the table editor,
-- and then ORDER BY sorts them as strings: profit_ballpark's largest value came
-- back as 9,900 when the real maximum is 212,000. SUM() at least raises
-- "function sum(text) does not exist"; the sort is silent. A chatbot asked for
-- the most profitable deal would answer confidently and wrongly.
--
-- Fixed at the source in build_database_export.py: renames carry the declared
-- type across, invented columns declare theirs in DERIVED_TYPES, and any column
-- still falling back to TEXT is now reported in MANIFEST.json.
--
-- A column type cannot be altered while a view depends on it, and v_deal_full
-- selects profit_ballpark. So the views come down here and 004 puts them back -
-- it now begins each definition with DROP VIEW IF EXISTS ... CASCADE, so it is
-- re-runnable. Run the two together; between them the database has no views:
--
--   psql -f 007_fix_numeric_column_types.sql
--   psql -f 004_create_views.sql
--
-- Both casts are lossless: every non-null value in both columns already matches
-- ^-?[0-9]+(\.[0-9]+)?$ - 191 of 191, and 293 of 293. The USING clause raises
-- rather than corrupting anything if that ever stops being true.

BEGIN;

-- CASCADE takes v_deal_top_20 and v_deal_bottom_20, which select from it.
DROP VIEW IF EXISTS v_deal_full CASCADE;
DROP VIEW IF EXISTS v_settlements_enriched CASCADE;

ALTER TABLE deal_economics
    ALTER COLUMN profit_ballpark TYPE NUMERIC(14,2)
    USING nullif(btrim(profit_ballpark), '')::numeric;

ALTER TABLE hud_settlements
    ALTER COLUMN contract_price TYPE NUMERIC(14,2)
    USING nullif(btrim(contract_price), '')::numeric;

INSERT INTO _migrations (name) VALUES ('007_fix_numeric_column_types')
    ON CONFLICT (name) DO NOTHING;

COMMIT;
