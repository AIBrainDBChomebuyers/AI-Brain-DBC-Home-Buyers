-- Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

-- Destroys all data.
DROP TABLE IF EXISTS rentals_cash_in_deal CASCADE;
DROP TABLE IF EXISTS quickbooks_pl CASCADE;
DROP TABLE IF EXISTS property_profit_breakdown CASCADE;
DROP TABLE IF EXISTS profit_reconciliation CASCADE;
DROP TABLE IF EXISTS performance_by_exit_strategy CASCADE;
DROP TABLE IF EXISTS performance_by_county CASCADE;
DROP TABLE IF EXISTS mls_listings CASCADE;
DROP TABLE IF EXISTS master_budget_line_items CASCADE;
DROP TABLE IF EXISTS master_budget CASCADE;
DROP TABLE IF EXISTS loan_statements CASCADE;
DROP TABLE IF EXISTS loan_activity CASCADE;
DROP TABLE IF EXISTS hud_settlements CASCADE;
DROP TABLE IF EXISTS focus_and_avoid CASCADE;
DROP TABLE IF EXISTS deal_economics CASCADE;
DROP TABLE IF EXISTS deal_aggregates CASCADE;
DROP TABLE IF EXISTS deal_portfolio CASCADE;
DROP TABLE IF EXISTS _migrations;
