-- Generated 2026-09-13 16:17 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

-- Sparsity is a correctness problem, not a cosmetic one. A column
-- filled on 2% of rows still answers AVG() with a number, and the
-- number is wrong in a way nothing in the result set reveals.

COMMENT ON TABLE deal_portfolio IS '256 rows, from the Deal Portfolio tab. internal.';
COMMENT ON COLUMN deal_portfolio.exit_strategy IS 'populated on 191 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.deal_source IS 'populated on 191 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sold_year IS 'populated on 174 of 256 rows (68%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sold_date IS 'populated on 155 of 256 rows (61%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sold_date_source IS 'populated on 173 of 256 rows (68%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.purchase_price IS 'populated on 191 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.purchase_date IS 'populated on 215 of 256 rows (84%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sale_price IS 'populated on 151 of 256 rows (59%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.contractor IS 'populated on 44 of 256 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.contractor_crew IS 'populated on 27 of 256 rows (11%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.house_type IS 'populated on 120 of 256 rows (47%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.house_style IS 'populated on 118 of 256 rows (46%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.beds IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.baths_full IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.baths_half IS 'populated on 48 of 256 rows (19%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sqft_above_grade IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sqft_total_finished IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sqft_below_grade_fin IS 'populated on 46 of 256 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sqft_below_grade_unfin IS 'populated on 48 of 256 rows (19%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.sqft_below_grade_total IS 'populated on 71 of 256 rows (28%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_list_date IS 'populated on 109 of 256 rows (43%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.year_built IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.yr_major_reno IS 'populated on 4 of 256 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.start_date IS 'populated on 19 of 256 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.completion_date IS 'populated on 5 of 256 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_number IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_status IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_list_price IS 'populated on 109 of 256 rows (43%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_original_price IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_close_price IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_close_date IS 'populated on 109 of 256 rows (43%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_dom IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.mls_cdom IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.buyer_financing IS 'populated on 108 of 256 rows (42%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.school_district IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.subdivision IS 'populated on 116 of 256 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.hud_purchase_file_no IS 'populated on 172 of 256 rows (67%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.hud_sale_file_no IS 'populated on 83 of 256 rows (32%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.hud_settlement_dates IS 'populated on 221 of 256 rows (86%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.lenders IS 'populated on 59 of 256 rows (23%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.purchase_date_source IS 'populated on 3 of 256 rows (1%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_portfolio.county_code IS 'populated on 189 of 256 rows (74%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE deal_aggregates IS '200 rows, from the Deal Aggregates tab. confidential.';
COMMENT ON COLUMN deal_aggregates.deal_source IS 'Rewritten on load from ''Wholesalers'' to ''Wholesaler'' so it joins to deal_portfolio.deal_source, which spells it the second way. Both spellings are in the source workbook.';
COMMENT ON COLUMN deal_aggregates.metric_value IS 'populated on 149 of 200 rows (74%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_aggregates.sold_year IS 'populated on 112 of 200 rows (56%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE deal_economics IS '256 rows, from the Deal Portfolio tab. confidential.';
COMMENT ON COLUMN deal_economics.profit IS 'The authoritative profit. Use this one. Reconciled against the settlement statements and the accounts; where it disagrees with profit_ballpark, this is the figure to quote. Populated on 193 of 256 rows (75%).';
COMMENT ON COLUMN deal_economics.profit_source IS 'populated on 193 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.gross_margin IS 'populated on 5 of 256 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.total_cash_in IS 'populated on 13 of 256 rows (5%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.total_cash_in_deal IS 'populated on 5 of 256 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.arv IS 'populated on 35 of 256 rows (14%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.budget_total IS 'populated on 46 of 256 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.budget_total_labor IS 'populated on 46 of 256 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.budget_total_materials IS 'populated on 46 of 256 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.actual_total_rehab IS 'populated on 28 of 256 rows (11%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.actual_rehab_labor IS 'populated on 28 of 256 rows (11%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.actual_rehab_materials IS 'populated on 22 of 256 rows (9%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.closing_costs_buyer IS 'populated on 27 of 256 rows (11%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.closing_costs_seller IS 'populated on 28 of 256 rows (11%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.total_holding_costs IS 'populated on 25 of 256 rows (10%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.top_20_flag IS 'populated on 191 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.deal_rank IS 'populated on 191 of 256 rows (75%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN deal_economics.profit_ballpark IS 'The Deal Types Overview figure, kept beside the authoritative one so the deals where the two disagree stay visible rather than being silently resolved. Disagrees with profit on 14 properties, by 75,091 in total. Do NOT use it to answer a profit question - prefer deal_economics.profit. Populated on 191 of 256 rows (75%).';

COMMENT ON TABLE focus_and_avoid IS '15 rows, from the Focus & Avoid tab. confidential.';

COMMENT ON TABLE hud_settlements IS '382 rows, from the HUD Settlements tab. restricted.';
COMMENT ON COLUMN hud_settlements.transaction_type IS 'Which side of the deal this settlement records: ''Purchase'' when DBC bought, ''Sale'' when DBC sold. It decides what contract_price means on the row.';
COMMENT ON COLUMN hud_settlements.file_number IS 'populated on 260 of 382 rows (68%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.buyer_name IS 'populated on 314 of 382 rows (82%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.seller_name IS 'populated on 292 of 382 rows (76%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.lender_name IS 'populated on 205 of 382 rows (54%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.property_city IS 'populated on 190 of 382 rows (50%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.property_state IS 'populated on 199 of 382 rows (52%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.property_zip IS 'populated on 199 of 382 rows (52%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.contract_price IS 'The contract sales price printed on THIS settlement - line 101 of a buyer''s HUD-1, line 401 of a seller''s. It is a PURCHASE price on rows where transaction_type = ''Purchase'' and a SALE price where it is ''Sale'', so it is never meaningful to aggregate without grouping or filtering on transaction_type. For a property''s resolved purchase and sale prices, use deal_portfolio.purchase_price and deal_portfolio.sale_price, which reconcile this against the listing and the accounts. Populated on 293 of 382 rows (77%).';
COMMENT ON COLUMN hud_settlements.loan_amount IS 'populated on 115 of 382 rows (30%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.earnest_deposit IS 'populated on 124 of 382 rows (32%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.gross_due_from_borrower IS 'populated on 127 of 382 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.gross_due_to_seller IS 'populated on 109 of 382 rows (29%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.cash_from_borrower IS 'populated on 192 of 382 rows (50%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN hud_settlements.cash_to_seller IS 'populated on 205 of 382 rows (54%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE loan_activity IS '277 rows, from the Loan Activity tab. restricted.';
COMMENT ON COLUMN loan_activity.loan_or_account_number IS 'populated on 109 of 277 rows (39%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.interest IS 'populated on 50 of 277 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.principal IS 'populated on 50 of 277 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.fees IS 'populated on 50 of 277 rows (18%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.balance_after IS 'populated on 109 of 277 rows (39%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.is_mezzanine IS 'populated on 168 of 277 rows (61%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.per_diem_rate IS 'populated on 164 of 277 rows (59%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_activity.amounts_raw IS 'populated on 42 of 277 rows (15%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE loan_statements IS '143 rows, from the Loan Statements tab. restricted.';
COMMENT ON COLUMN loan_statements.loan_or_account_number IS 'populated on 121 of 143 rows (85%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.property_key IS 'populated on 121 of 143 rows (85%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.canonical_address IS 'populated on 121 of 143 rows (85%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.property_city IS 'populated on 120 of 143 rows (84%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.property_state IS 'populated on 120 of 143 rows (84%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.property_zip IS 'populated on 120 of 143 rows (84%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.maturity_date IS 'populated on 113 of 143 rows (79%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.interest_rate_pct IS 'populated on 71 of 143 rows (50%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.next_payment_date IS 'populated on 46 of 143 rows (32%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.undrawn_amount IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.remaining_interest IS 'populated on 42 of 143 rows (29%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_principal IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_interest IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_advances IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_fees IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_total IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.payment_period IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.principal_period IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.principal_ytd IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.principal_lifetime IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.interest_period IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.interest_ytd IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.interest_lifetime IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.fees_period IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.fees_ytd IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.fees_lifetime IS 'populated on 49 of 143 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.statement_format IS 'populated on 50 of 143 rows (35%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.due_date IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.close_date IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.disbursed_principal_balance IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.remaining_construction_funds IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.escrow_balance IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.other_fees_due IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.past_due_amount IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.amount_already_paid IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.late_fee_amount IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.loan_officer IS 'populated on 47 of 143 rows (33%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.summary_year IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.origination_date IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.interest_paid_ytd IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.beginning_principal_balance IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.real_estate_taxes_paid IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.ending_principal_balance IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.insurance_paid IS 'populated on 3 of 143 rows (2%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.reserve_balance IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.impound_balance IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.payment_due_date IS 'populated on 17 of 143 rows (12%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.unpaid_interest IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.unpaid_charges IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.late_charges_due IS 'populated on 21 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.statement_entity IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.account_current_balance IS 'populated on 2 of 143 rows (1%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN loan_statements.property_count IS 'populated on 22 of 143 rows (15%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE master_budget IS '46 rows, from the Master Budget tab. internal.';
COMMENT ON COLUMN master_budget.arv IS 'populated on 35 of 46 rows (76%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN master_budget.project_timeline IS 'populated on 36 of 46 rows (78%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN master_budget.layout_summary IS 'populated on 41 of 46 rows (89%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN master_budget.agreed_labor_budget IS 'populated on 3 of 46 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN master_budget.other_labor_total IS 'populated on 11 of 46 rows (24%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE master_budget_line_items IS '3,374 rows, from the Master Budget Line Items tab. internal.';
COMMENT ON COLUMN master_budget_line_items.description IS 'populated on 2,919 of 3,374 rows (87%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN master_budget_line_items.method_or_note IS 'populated on 2,985 of 3,374 rows (88%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE mls_listings IS '116 rows, from the MLS Listings tab. internal.';
COMMENT ON COLUMN mls_listings.baths_half IS 'populated on 48 of 116 rows (41%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.total_rooms IS 'populated on 8 of 116 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.sqft_below_grade_fin IS 'populated on 46 of 116 rows (40%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.sqft_below_grade_unfin IS 'populated on 48 of 116 rows (41%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.sqft_below_grade_total IS 'populated on 70 of 116 rows (60%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.previous_list_price IS 'populated on 53 of 116 rows (46%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.owner_name IS 'populated on 76 of 116 rows (66%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.property_condition IS 'populated on 19 of 116 rows (16%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN mls_listings.yr_major_reno IS 'populated on 4 of 116 rows (3%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE performance_by_county IS '12 rows, from the Perf by County tab. confidential.';
COMMENT ON COLUMN performance_by_county.total_profit IS 'Pre-computed from profit_ballpark, NOT from deal_economics.profit, so it disagrees with SUM(deal_economics.profit) over the same deals. For the reconciled number, sum deal_economics.profit and group by deal_portfolio.county_code.';

COMMENT ON TABLE performance_by_exit_strategy IS '4 rows, from the Perf by Exit Strategy tab. confidential.';
COMMENT ON COLUMN performance_by_exit_strategy.total_profit IS 'Pre-computed from profit_ballpark, NOT from deal_economics.profit. It therefore disagrees with SUM(deal_economics.profit) over the same deals: 3,174,200 against 3,249,291 for Fix and Flip, and 327,100 against 354,823 for Wholetail. Quote this only as the Deal Types Overview figure; for the reconciled number, sum deal_economics.profit.';

COMMENT ON TABLE profit_reconciliation IS '136 rows, from the Accounting Summary tab. confidential.';
COMMENT ON COLUMN profit_reconciliation.house_type_source IS 'populated on 120 of 136 rows (88%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN profit_reconciliation.house_style_source IS 'populated on 118 of 136 rows (87%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN profit_reconciliation.lockbox IS 'populated on 60 of 136 rows (44%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN profit_reconciliation.profit_breakdown IS 'populated on 16 of 136 rows (12%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN profit_reconciliation.profit_quickbooks IS 'populated on 28 of 136 rows (21%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN profit_reconciliation.loan_draw_amount IS 'populated on 5 of 136 rows (4%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE property_profit_breakdown IS '29 rows, from the Property Profit Breakdown tab. confidential.';
COMMENT ON COLUMN property_profit_breakdown.purchase_date IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.sale_date IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.lockbox IS 'populated on 20 of 29 rows (69%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.purchase_price IS 'populated on 15 of 29 rows (52%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.sale_price IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.cash_out IS 'populated on 23 of 29 rows (79%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.cash_in_short IS 'populated on 23 of 29 rows (79%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.total_cash_in IS 'populated on 8 of 29 rows (28%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.total_cash_from_sale IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.cash_received IS 'populated on 7 of 29 rows (24%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.total_profit IS 'populated on 11 of 29 rows (38%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.profit IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.mel_profit IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.mason_profit IS 'populated on 10 of 29 rows (34%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.expenses_total IS 'populated on 16 of 29 rows (55%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.labor_total IS 'populated on 6 of 29 rows (21%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.loan_at_end_of_sale IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.hd_roof_hvac_total IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.amazon_total IS 'populated on 2 of 29 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.other_materials_total IS 'populated on 2 of 29 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.hauling IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.survey IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.staging_photos IS 'populated on 2 of 29 rows (7%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.staging_extension IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.insurance IS 'populated on 11 of 29 rows (38%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.bge IS 'populated on 13 of 29 rows (45%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.points IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.interest IS 'populated on 7 of 29 rows (24%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.dispositions IS 'populated on 15 of 29 rows (52%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.sale_out IS 'populated on 1 of 29 rows (3%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN property_profit_breakdown.gross_margin IS 'populated on 5 of 29 rows (17%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE quickbooks_pl IS '28 rows, from the QuickBooks P&L tab. restricted.';
COMMENT ON COLUMN quickbooks_pl.rehab_materials IS 'populated on 22 of 28 rows (79%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.total_operating_expenses IS 'populated on 1 of 28 rows (4%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.total_holding_costs IS 'populated on 25 of 28 rows (89%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.hoa IS 'populated on 4 of 28 rows (14%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.insurance_expenses IS 'populated on 16 of 28 rows (57%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.interest_expenses IS 'populated on 17 of 28 rows (61%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.utilities_electricity IS 'populated on 22 of 28 rows (79%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN quickbooks_pl.utilities_water IS 'populated on 1 of 28 rows (4%) - do not aggregate without a NOT NULL filter.';

COMMENT ON TABLE rentals_cash_in_deal IS '5 rows, from the Rentals Cash in Deal tab. confidential.';
COMMENT ON COLUMN rentals_cash_in_deal.initial_cash_out IS 'populated on 4 of 5 rows (80%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN rentals_cash_in_deal.cash_out_to_refinance IS 'populated on 3 of 5 rows (60%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN rentals_cash_in_deal.cash_back_from_refinance IS 'populated on 1 of 5 rows (20%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN rentals_cash_in_deal.cash_from_sale IS 'populated on 1 of 5 rows (20%) - do not aggregate without a NOT NULL filter.';
COMMENT ON COLUMN rentals_cash_in_deal.cash_in_for_refinance IS 'populated on 4 of 5 rows (80%) - do not aggregate without a NOT NULL filter.';

INSERT INTO _migrations (name) VALUES ('005_add_comments')
    ON CONFLICT (name) DO NOTHING;
