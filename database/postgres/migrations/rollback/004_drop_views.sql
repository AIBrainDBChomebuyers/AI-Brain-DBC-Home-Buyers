-- Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

DROP VIEW IF EXISTS v_deal_top_20;
DROP VIEW IF EXISTS v_deal_bottom_20;
DROP VIEW IF EXISTS v_deal_full;
DROP VIEW IF EXISTS v_property_public;
DROP VIEW IF EXISTS v_budget_vs_actual;
DROP VIEW IF EXISTS v_loan_activity_enriched;
DROP VIEW IF EXISTS v_settlements_enriched;
DELETE FROM _migrations WHERE name = '004_create_views';
