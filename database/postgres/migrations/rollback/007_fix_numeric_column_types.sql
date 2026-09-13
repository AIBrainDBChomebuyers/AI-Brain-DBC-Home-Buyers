-- Rollback 007. Returns both columns to TEXT, and drops the views that depend
-- on them; re-run 004 afterwards to put those back.
-- Reverting reintroduces the string-sort defect. This exists so the sequence
-- is symmetrical, not because going back is a good idea.
BEGIN;
DROP VIEW IF EXISTS v_deal_full CASCADE;
DROP VIEW IF EXISTS v_settlements_enriched CASCADE;
ALTER TABLE deal_economics  ALTER COLUMN profit_ballpark TYPE TEXT USING profit_ballpark::text;
ALTER TABLE hud_settlements ALTER COLUMN contract_price  TYPE TEXT USING contract_price::text;
DELETE FROM _migrations WHERE name = '007_fix_numeric_column_types';
COMMIT;
