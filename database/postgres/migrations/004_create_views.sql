-- Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

-- Pre-joined shapes, so text-to-SQL reads one relation instead of
-- composing a join. security_invoker = true is what keeps RLS
-- applying through them: without it a view runs as its owner and
-- becomes a way to read around a policy.

-- Economics joined to property facts and the listing. The default shape for a profitability question.
CREATE VIEW v_deal_full WITH (security_invoker = true) AS
SELECT
    b.*,
    p.canonical_address AS p_canonical_address,
    p.property_city AS p_property_city,
    p.property_state AS p_property_state,
    p.property_zip AS p_property_zip,
    p.property_county AS p_property_county,
    p.deal_status AS p_deal_status,
    p.exit_strategy AS p_exit_strategy,
    p.sold_year AS p_sold_year,
    p.sold_date AS p_sold_date,
    p.purchase_date AS p_purchase_date,
    p.purchase_price AS p_purchase_price,
    p.sale_price AS p_sale_price,
    m.beds AS m_beds,
    m.baths_full AS m_baths_full,
    m.dom AS m_dom,
    m.cdom AS m_cdom,
    m.close_price AS m_close_price,
    m.year_built AS m_year_built,
    m.sqft_total_finished AS m_sqft_total_finished
FROM deal_economics b
    LEFT JOIN deal_portfolio p ON p.property_key = b.property_key
    LEFT JOIN mls_listings m ON m.property_key = b.property_key;
GRANT SELECT ON v_deal_full TO ai_brain_app;

-- Property facts and listing detail. No economics.
CREATE VIEW v_property_public WITH (security_invoker = true) AS
SELECT
    b.*,
    m.beds AS m_beds,
    m.baths_full AS m_baths_full,
    m.dom AS m_dom,
    m.cdom AS m_cdom,
    m.close_price AS m_close_price,
    m.year_built AS m_year_built,
    m.sqft_total_finished AS m_sqft_total_finished
FROM deal_portfolio b
    LEFT JOIN mls_listings m ON m.property_key = b.property_key;
GRANT SELECT ON v_property_public TO ai_brain_app;

-- Construction line items against the deal. The shape behind 'estimated versus actual renovation cost'.
CREATE VIEW v_budget_vs_actual WITH (security_invoker = true) AS
SELECT
    b.*,
    p.canonical_address AS p_canonical_address,
    p.property_city AS p_property_city,
    p.property_state AS p_property_state,
    p.property_zip AS p_property_zip,
    p.property_county AS p_property_county,
    p.deal_status AS p_deal_status,
    p.exit_strategy AS p_exit_strategy,
    p.sold_year AS p_sold_year,
    p.sold_date AS p_sold_date,
    p.purchase_date AS p_purchase_date,
    p.purchase_price AS p_purchase_price,
    p.sale_price AS p_sale_price,
    e.budget_total AS e_budget_total,
    e.actual_total_rehab AS e_actual_total_rehab
FROM master_budget_line_items b
    LEFT JOIN deal_portfolio p ON p.property_key = b.property_key
    LEFT JOIN deal_economics e ON e.property_key = b.property_key;
GRANT SELECT ON v_budget_vs_actual TO ai_brain_app;

-- Loan transactions in deal context.
CREATE VIEW v_loan_activity_enriched WITH (security_invoker = true) AS
SELECT
    b.*,
    p.canonical_address AS p_canonical_address,
    p.property_city AS p_property_city,
    p.property_state AS p_property_state,
    p.property_zip AS p_property_zip,
    p.property_county AS p_property_county,
    p.deal_status AS p_deal_status,
    p.exit_strategy AS p_exit_strategy,
    p.sold_year AS p_sold_year,
    p.sold_date AS p_sold_date,
    p.purchase_date AS p_purchase_date,
    p.purchase_price AS p_purchase_price,
    p.sale_price AS p_sale_price
FROM loan_activity b
    LEFT JOIN deal_portfolio p ON p.property_key = b.property_key;
GRANT SELECT ON v_loan_activity_enriched TO ai_brain_app;

-- Settlements in deal context.
CREATE VIEW v_settlements_enriched WITH (security_invoker = true) AS
SELECT
    b.*,
    CASE WHEN b.transaction_type = 'Purchase' THEN b.contract_price END AS purchase_price,
    CASE WHEN b.transaction_type = 'Sale' THEN b.contract_price END AS sale_price,
    p.canonical_address AS p_canonical_address,
    p.property_city AS p_property_city,
    p.property_state AS p_property_state,
    p.property_zip AS p_property_zip,
    p.property_county AS p_property_county,
    p.deal_status AS p_deal_status,
    p.exit_strategy AS p_exit_strategy,
    p.sold_year AS p_sold_year,
    p.sold_date AS p_sold_date,
    p.purchase_date AS p_purchase_date,
    p.purchase_price AS p_purchase_price,
    p.sale_price AS p_sale_price
FROM hud_settlements b
    LEFT JOIN deal_portfolio p ON p.property_key = b.property_key;
GRANT SELECT ON v_settlements_enriched TO ai_brain_app;

-- The Top 20% Deals tab. Was a table; is a filter, so it cannot disagree with the ranking it came from.
CREATE VIEW v_deal_top_20 WITH (security_invoker = true) AS
SELECT * FROM v_deal_full WHERE top_20_flag = 'Yes';
GRANT SELECT ON v_deal_top_20 TO ai_brain_app;

-- The Bottom 20% Deals tab. Symmetric with the top: the same number of deals, taken from the other end of the same rank.
CREATE VIEW v_deal_bottom_20 WITH (security_invoker = true) AS
SELECT * FROM v_deal_full
WHERE deal_rank > (
    SELECT count(*) - count(*) FILTER (WHERE top_20_flag = 'Yes')
    FROM deal_economics WHERE deal_rank IS NOT NULL
);
GRANT SELECT ON v_deal_bottom_20 TO ai_brain_app;

INSERT INTO _migrations (name) VALUES ('004_create_views')
    ON CONFLICT (name) DO NOTHING;
