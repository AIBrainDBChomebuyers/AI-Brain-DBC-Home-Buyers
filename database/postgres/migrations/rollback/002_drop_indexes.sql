-- Generated 2026-09-13 14:58 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

DROP INDEX IF EXISTS ix_deal_portfolio_roles;
DROP INDEX IF EXISTS ix_deal_aggregates_roles;
DROP INDEX IF EXISTS ix_deal_economics_roles;
DROP INDEX IF EXISTS ix_deal_economics_property;
DROP INDEX IF EXISTS ix_focus_and_avoid_roles;
DROP INDEX IF EXISTS ix_hud_settlements_roles;
DROP INDEX IF EXISTS ix_hud_settlements_property;
DROP INDEX IF EXISTS ix_hud_settlements_file;
DROP INDEX IF EXISTS ix_loan_activity_roles;
DROP INDEX IF EXISTS ix_loan_activity_property;
DROP INDEX IF EXISTS ix_loan_activity_file;
DROP INDEX IF EXISTS ix_loan_statements_roles;
DROP INDEX IF EXISTS ix_loan_statements_property;
DROP INDEX IF EXISTS ix_loan_statements_file;
DROP INDEX IF EXISTS ix_master_budget_roles;
DROP INDEX IF EXISTS ix_master_budget_property;
DROP INDEX IF EXISTS ix_master_budget_file;
DROP INDEX IF EXISTS ix_master_budget_line_items_roles;
DROP INDEX IF EXISTS ix_master_budget_line_items_property;
DROP INDEX IF EXISTS ix_master_budget_line_items_file;
DROP INDEX IF EXISTS ix_mls_listings_roles;
DROP INDEX IF EXISTS ix_mls_listings_property;
DROP INDEX IF EXISTS ix_mls_listings_file;
DROP INDEX IF EXISTS ix_performance_by_county_roles;
DROP INDEX IF EXISTS ix_performance_by_exit_strategy_roles;
DROP INDEX IF EXISTS ix_profit_reconciliation_roles;
DROP INDEX IF EXISTS ix_profit_reconciliation_property;
DROP INDEX IF EXISTS ix_property_profit_breakdown_roles;
DROP INDEX IF EXISTS ix_property_profit_breakdown_property;
DROP INDEX IF EXISTS ix_property_profit_breakdown_file;
DROP INDEX IF EXISTS ix_quickbooks_pl_roles;
DROP INDEX IF EXISTS ix_quickbooks_pl_property;
DROP INDEX IF EXISTS ix_quickbooks_pl_file;
DROP INDEX IF EXISTS ix_rentals_cash_in_deal_roles;
DROP INDEX IF EXISTS ix_rentals_cash_in_deal_property;
DROP INDEX IF EXISTS ix_rentals_cash_in_deal_file;
DROP INDEX IF EXISTS ix_deal_portfolio_deal_status;
DROP INDEX IF EXISTS ix_deal_portfolio_property_county;
DROP INDEX IF EXISTS ix_deal_portfolio_sold_year;
DROP INDEX IF EXISTS ix_deal_portfolio_exit_strategy;
DROP INDEX IF EXISTS ix_loan_activity_lender;
DELETE FROM _migrations WHERE name = '002_create_indexes';
