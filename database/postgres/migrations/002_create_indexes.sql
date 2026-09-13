-- Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

-- allowed_roles is in the WHERE clause of literally every query
-- once RLS is on, so it is indexed first and with GIN, which is
-- what makes the array-overlap operator fast.

CREATE INDEX ix_deal_portfolio_roles ON deal_portfolio USING GIN (allowed_roles);
CREATE INDEX ix_deal_aggregates_roles ON deal_aggregates USING GIN (allowed_roles);
CREATE INDEX ix_deal_economics_roles ON deal_economics USING GIN (allowed_roles);
CREATE INDEX ix_deal_economics_property ON deal_economics (property_key);
CREATE INDEX ix_focus_and_avoid_roles ON focus_and_avoid USING GIN (allowed_roles);
CREATE INDEX ix_hud_settlements_roles ON hud_settlements USING GIN (allowed_roles);
CREATE INDEX ix_hud_settlements_property ON hud_settlements (property_key);
CREATE INDEX ix_hud_settlements_file ON hud_settlements (source_file);
CREATE INDEX ix_loan_activity_roles ON loan_activity USING GIN (allowed_roles);
CREATE INDEX ix_loan_activity_property ON loan_activity (property_key);
CREATE INDEX ix_loan_activity_file ON loan_activity (source_file);
CREATE INDEX ix_loan_statements_roles ON loan_statements USING GIN (allowed_roles);
CREATE INDEX ix_loan_statements_property ON loan_statements (property_key);
CREATE INDEX ix_loan_statements_file ON loan_statements (source_file);
CREATE INDEX ix_master_budget_roles ON master_budget USING GIN (allowed_roles);
CREATE INDEX ix_master_budget_property ON master_budget (property_key);
CREATE INDEX ix_master_budget_file ON master_budget (source_file);
CREATE INDEX ix_master_budget_line_items_roles ON master_budget_line_items USING GIN (allowed_roles);
CREATE INDEX ix_master_budget_line_items_property ON master_budget_line_items (property_key);
CREATE INDEX ix_master_budget_line_items_file ON master_budget_line_items (source_file);
CREATE INDEX ix_mls_listings_roles ON mls_listings USING GIN (allowed_roles);
CREATE INDEX ix_mls_listings_property ON mls_listings (property_key);
CREATE INDEX ix_mls_listings_file ON mls_listings (source_file);
CREATE INDEX ix_performance_by_county_roles ON performance_by_county USING GIN (allowed_roles);
CREATE INDEX ix_performance_by_exit_strategy_roles ON performance_by_exit_strategy USING GIN (allowed_roles);
CREATE INDEX ix_profit_reconciliation_roles ON profit_reconciliation USING GIN (allowed_roles);
CREATE INDEX ix_profit_reconciliation_property ON profit_reconciliation (property_key);
CREATE INDEX ix_property_profit_breakdown_roles ON property_profit_breakdown USING GIN (allowed_roles);
CREATE INDEX ix_property_profit_breakdown_property ON property_profit_breakdown (property_key);
CREATE INDEX ix_property_profit_breakdown_file ON property_profit_breakdown (source_file);
CREATE INDEX ix_quickbooks_pl_roles ON quickbooks_pl USING GIN (allowed_roles);
CREATE INDEX ix_quickbooks_pl_property ON quickbooks_pl (property_key);
CREATE INDEX ix_quickbooks_pl_file ON quickbooks_pl (source_file);
CREATE INDEX ix_rentals_cash_in_deal_roles ON rentals_cash_in_deal USING GIN (allowed_roles);
CREATE INDEX ix_rentals_cash_in_deal_property ON rentals_cash_in_deal (property_key);
CREATE INDEX ix_rentals_cash_in_deal_file ON rentals_cash_in_deal (source_file);

-- Columns the chatbot groups and filters by.
CREATE INDEX ix_deal_portfolio_deal_status ON deal_portfolio (deal_status);
CREATE INDEX ix_deal_portfolio_property_county ON deal_portfolio (property_county);
CREATE INDEX ix_deal_portfolio_sold_year ON deal_portfolio (sold_year);
CREATE INDEX ix_deal_portfolio_exit_strategy ON deal_portfolio (exit_strategy);
CREATE INDEX ix_loan_activity_lender ON loan_activity (lender);

INSERT INTO _migrations (name) VALUES ('002_create_indexes')
    ON CONFLICT (name) DO NOTHING;
