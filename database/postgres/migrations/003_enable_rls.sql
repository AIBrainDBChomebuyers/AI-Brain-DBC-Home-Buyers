-- Generated 2026-09-13 14:58 UTC by build_migrations.py from db_export/schema.json
-- Do not edit by hand; re-run the generator instead.
-- Requires PostgreSQL 15+ (security_invoker views).

-- The permission boundary.
--
-- The application opens a transaction and declares who is asking:
--
--     BEGIN;
--     SET LOCAL app.roles = 'acquisitions,va';
--     SELECT ... ;                     -- any SQL at all
--     COMMIT;
--
-- Every policy below filters on array overlap between those roles and the
-- row's allowed_roles. Three consequences worth being explicit about:
--
--   1. The orchestrator cannot forget the filter. It is not in the generated
--      SQL, so a model that writes `SELECT * FROM deal_economics` gets back
--      the rows that user may see and nothing else.
--   2. If app.roles is never set, current_setting returns NULL,
--      string_to_array returns NULL, && returns NULL, and the row is
--      excluded. It fails closed.
--   3. ai_brain_app is granted SELECT and nothing else, so no generated
--      statement can write, drop or alter anything whatever it says.

CREATE ROLE ai_brain_app NOLOGIN;
-- Grant LOGIN and a password in your environment, not in version control:
--   ALTER ROLE ai_brain_app LOGIN PASSWORD '...';

ALTER TABLE deal_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE deal_portfolio FORCE ROW LEVEL SECURITY;
CREATE POLICY p_deal_portfolio_read ON deal_portfolio FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON deal_portfolio TO ai_brain_app;

ALTER TABLE deal_aggregates ENABLE ROW LEVEL SECURITY;
ALTER TABLE deal_aggregates FORCE ROW LEVEL SECURITY;
CREATE POLICY p_deal_aggregates_read ON deal_aggregates FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON deal_aggregates TO ai_brain_app;

ALTER TABLE deal_economics ENABLE ROW LEVEL SECURITY;
ALTER TABLE deal_economics FORCE ROW LEVEL SECURITY;
CREATE POLICY p_deal_economics_read ON deal_economics FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON deal_economics TO ai_brain_app;

ALTER TABLE focus_and_avoid ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_and_avoid FORCE ROW LEVEL SECURITY;
CREATE POLICY p_focus_and_avoid_read ON focus_and_avoid FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON focus_and_avoid TO ai_brain_app;

ALTER TABLE hud_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE hud_settlements FORCE ROW LEVEL SECURITY;
CREATE POLICY p_hud_settlements_read ON hud_settlements FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON hud_settlements TO ai_brain_app;

ALTER TABLE loan_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_activity FORCE ROW LEVEL SECURITY;
CREATE POLICY p_loan_activity_read ON loan_activity FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON loan_activity TO ai_brain_app;

ALTER TABLE loan_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE loan_statements FORCE ROW LEVEL SECURITY;
CREATE POLICY p_loan_statements_read ON loan_statements FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON loan_statements TO ai_brain_app;

ALTER TABLE master_budget ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_budget FORCE ROW LEVEL SECURITY;
CREATE POLICY p_master_budget_read ON master_budget FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON master_budget TO ai_brain_app;

ALTER TABLE master_budget_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_budget_line_items FORCE ROW LEVEL SECURITY;
CREATE POLICY p_master_budget_line_items_read ON master_budget_line_items FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON master_budget_line_items TO ai_brain_app;

ALTER TABLE mls_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE mls_listings FORCE ROW LEVEL SECURITY;
CREATE POLICY p_mls_listings_read ON mls_listings FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON mls_listings TO ai_brain_app;

ALTER TABLE performance_by_county ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_by_county FORCE ROW LEVEL SECURITY;
CREATE POLICY p_performance_by_county_read ON performance_by_county FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON performance_by_county TO ai_brain_app;

ALTER TABLE performance_by_exit_strategy ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_by_exit_strategy FORCE ROW LEVEL SECURITY;
CREATE POLICY p_performance_by_exit_strategy_read ON performance_by_exit_strategy FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON performance_by_exit_strategy TO ai_brain_app;

ALTER TABLE profit_reconciliation ENABLE ROW LEVEL SECURITY;
ALTER TABLE profit_reconciliation FORCE ROW LEVEL SECURITY;
CREATE POLICY p_profit_reconciliation_read ON profit_reconciliation FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON profit_reconciliation TO ai_brain_app;

ALTER TABLE property_profit_breakdown ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_profit_breakdown FORCE ROW LEVEL SECURITY;
CREATE POLICY p_property_profit_breakdown_read ON property_profit_breakdown FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON property_profit_breakdown TO ai_brain_app;

ALTER TABLE quickbooks_pl ENABLE ROW LEVEL SECURITY;
ALTER TABLE quickbooks_pl FORCE ROW LEVEL SECURITY;
CREATE POLICY p_quickbooks_pl_read ON quickbooks_pl FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON quickbooks_pl TO ai_brain_app;

ALTER TABLE rentals_cash_in_deal ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals_cash_in_deal FORCE ROW LEVEL SECURITY;
CREATE POLICY p_rentals_cash_in_deal_read ON rentals_cash_in_deal FOR SELECT
    USING ((SELECT string_to_array(current_setting('app.roles', true), ',')) && allowed_roles);
GRANT SELECT ON rentals_cash_in_deal TO ai_brain_app;

-- FORCE ROW LEVEL SECURITY above binds the table owner too, and the only
-- policies here are FOR SELECT. So without an exemption the loader cannot
-- write at all - its INSERT ... ON CONFLICT DO UPDATE fails outright rather
-- than quietly returning fewer rows.
--
-- Which role that is depends on where this runs: ai_brain_owner locally, but
-- `postgres` on Supabase and most managed hosts. Naming one hard-codes the
-- environment, so this grants it to whoever is running the migration, and
-- says so plainly when it cannot.
DO $$
DECLARE
    exempt boolean;
BEGIN
    SELECT rolbypassrls INTO exempt FROM pg_roles WHERE rolname = current_user;
    IF exempt THEN
        RAISE NOTICE 'loader role % already bypasses RLS', current_user;
    ELSE
        BEGIN
            EXECUTE format('ALTER ROLE %I BYPASSRLS', current_user);
            RAISE NOTICE 'granted BYPASSRLS to %', current_user;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING
                'cannot grant BYPASSRLS to % (%). Load the data BEFORE this '
                'migration: run 001, 002, load_data.py, then 003-005.',
                current_user, SQLERRM;
        END;
    END IF;
END
$$;

-- Close the PostgREST surface.
--
-- On a managed host every table in `public` is also reachable through an
-- auto-generated REST API, and Supabase grants ALL on that schema to `anon`
-- and `authenticated` by default. RLS catches the data tables, but bookkeeping
-- tables have no policy - _migrations was readable and TRUNCATE-able by anyone
-- holding a publishable key, which is public by design.
--
-- Nothing here uses PostgREST; the application connects as the app role over
-- a pooler. So the grants go, rather than being papered over with policies:
-- no grant is a stronger statement than a policy that returns nothing.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon, authenticated;
        REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
        REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon, authenticated;
        REVOKE USAGE ON SCHEMA public FROM anon, authenticated;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public
            REVOKE ALL ON TABLES FROM anon, authenticated;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public
            REVOKE ALL ON SEQUENCES FROM anon, authenticated;
        RAISE NOTICE 'revoked PostgREST grants from anon and authenticated';
    END IF;
END
$$;

-- The migration ledger carries no business data, but it should not be
-- writable by a web client either. No policy: nothing but the migration
-- runner, which bypasses RLS, has any business reading it.
ALTER TABLE _migrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE _migrations FORCE ROW LEVEL SECURITY;

INSERT INTO _migrations (name) VALUES ('003_enable_rls')
    ON CONFLICT (name) DO NOTHING;
