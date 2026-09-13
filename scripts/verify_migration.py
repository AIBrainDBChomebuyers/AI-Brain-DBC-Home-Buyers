#!/usr/bin/env python3
"""Verify Supabase against the workbook that produced it.

Not a spot check. Every table, every row, every column, compared value by
value against DBC_Client_Review.xlsx - the file the export was built from.

Seven checks, in the order a doubt would arise:

  1  row counts        every table has as many rows as its workbook tab
  2  values            every cell equals the workbook cell it came from
  3  derived columns   the three columns with no workbook header of their own
  4  dropped columns   the 14 columns the export left out really were empty
  5  fill rates        nothing arrived completely null
  6  RLS               each of the six roles sees exactly its own tables
  7  joins             foreign keys indexed, no orphans, categorical values
                       agree across tables, no numbers hiding in TEXT columns

Check 6 must connect as the application role. Connecting as `postgres`
proves nothing: it holds BYPASSRLS, so every policy is skipped and every
table looks readable to every role.

    python3 scripts/verify_migration.py            # all seven
    python3 scripts/verify_migration.py --quick    # skip 2, the slow one
"""
from __future__ import annotations

import datetime as dt
import json
import math
import os
import re
import sys
from decimal import Decimal
from pathlib import Path

import pandas as pd
import psycopg

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
EXTRACTION = ROOT.parent / "Data Retrieval" / "extraction_tool" / "client_review"
WORKBOOK = EXTRACTION / "deliverables" / "DBC_Client_Review.xlsx"
MANIFEST = EXTRACTION / "db_export" / "MANIFEST.json"

# tab -> table. Mirrors POSTGRES_TABLES in build_database_export.py; if that
# map changes this one has to change with it, and check 1 will say so.
TAB2TABLE = {
    "Deal Portfolio": "deal_portfolio",
    "MLS Listings": "mls_listings",
    "Deal Aggregates": "deal_aggregates",
    "Perf by Exit Strategy": "performance_by_exit_strategy",
    "Perf by County": "performance_by_county",
    "Focus & Avoid": "focus_and_avoid",
    "Accounting Summary": "profit_reconciliation",
    "QuickBooks P&L": "quickbooks_pl",
    "Property Profit Breakdown": "property_profit_breakdown",
    "Master Budget": "master_budget",
    "Master Budget Line Items": "master_budget_line_items",
    "Rentals Cash in Deal": "rentals_cash_in_deal",
    "HUD Settlements": "hud_settlements",
    "Loan Statements": "loan_statements",
    "Loan Activity": "loan_activity",
}

# deal_economics has no tab: the export splits the money columns off Deal
# Portfolio so a VA can read an address without reading the profit on it.
ECONOMICS_FROM = "Deal Portfolio"

# Added by the export to every table, so absent from every tab.
ENVELOPE = {"row_key", "source_tab", "source_row",
            "department", "sensitivity", "allowed_roles"}

# Columns that hold only digits and are still correctly TEXT. A ZIP is not a
# quantity - you never add two of them, and 07030 must keep its leading zero.
# Same for account and lockbox numbers. Check 7 would otherwise report these
# every run and train the reader to skim past real findings.
TEXT_BY_DESIGN = {"property_zip", "loan_or_account_number", "lockbox",
                  "hud_settlement_dates"}

# Left out of the load because they hold one value or none. Check 4 proves it.
DROPPED = {
    "HUD Settlements": ["total_settlement_charges", "doc_type"],
    "Master Budget": ["lowes_materials_total", "construction_start_proxy_source",
                      "doc_type"],
    "MLS Listings": ["doc_type"],
    "Accounting Summary": ["deal_source_source"],
    "Property Profit Breakdown": ["doc_type"],
    "QuickBooks P&L": ["doc_type"],
    "Rentals Cash in Deal": ["other_labor_total", "home_depot_total",
                             "amazon_total", "vendor_total", "doc_type"],
}

# Who may read what, from POSTGRES_TABLES. Check 6 asserts the database
# agrees, one role at a time.
EVERYONE = ["executive", "acquisitions", "construction",
            "property_management", "accounting", "va"]
EXPECTED_ROLES = {
    "deal_portfolio": EVERYONE,
    "mls_listings": EVERYONE,
    "deal_economics": ["executive", "acquisitions", "accounting"],
    "deal_aggregates": ["executive", "acquisitions"],
    "performance_by_exit_strategy": ["executive", "acquisitions"],
    "performance_by_county": ["executive", "acquisitions"],
    "focus_and_avoid": ["executive", "acquisitions"],
    "profit_reconciliation": ["executive", "accounting"],
    "quickbooks_pl": ["executive", "accounting"],
    "property_profit_breakdown": ["executive", "accounting"],
    "master_budget": ["executive", "acquisitions", "construction", "accounting"],
    "master_budget_line_items": ["executive", "acquisitions", "construction",
                                 "accounting"],
    "rentals_cash_in_deal": ["executive", "property_management", "accounting"],
    "hud_settlements": ["executive", "acquisitions", "accounting"],
    "loan_statements": ["executive", "accounting"],
    "loan_activity": ["executive", "accounting"],
}

failures: list[str] = []


def expected_value_maps() -> dict[tuple[str, str], dict[str, str]]:
    """Whole-column value rewrites the export applies, from its own manifest.

    Distinct from expected_corrections() below, which names individual rows.
    These apply to every row of one column: Deal Aggregates spells it
    "Wholesalers" and Deal Portfolio spells it "Wholesaler", both straight from
    the workbook, and the join between them returned nothing at all - not an
    error, zero rows, for 45 aggregate rows and 48 properties. The export now
    rewrites the aggregate side to match the spine.

    Returns {(table, column): {workbook value: database value}}.
    """
    if not MANIFEST.exists():
        return {}
    warnings = json.loads(MANIFEST.read_text()).get("warnings", [])
    line = next((w for w in warnings if "value spellings reconciled" in w), None)
    if not line:
        return {}
    out: dict[tuple[str, str], dict[str, str]] = {}
    for part in line.split(":", 1)[1].split(";"):
        m = re.search(r"(\w+)\.(\w+):\s*'(.*?)'\s*->\s*'(.*?)'", part.strip())
        if m:
            out.setdefault((m.group(1), m.group(2)), {})[m.group(3)] = m.group(4)
    return out


def expected_corrections() -> dict[tuple[str, str], tuple[str, str]]:
    """The values the export deliberately changed, read from its own manifest.

    Three county names on the Deal Portfolio tab disagree with the county_code
    the same property carries on Deal History, and the export trusts the code.
    So three cells are *meant* to differ, and check 2 would report them
    forever. Reading them from the manifest rather than hard-coding them means
    a fourth correction shows up as a diff to look at, and a correction that
    silently stops happening shows up too.

    Returns {(property_key, column): (workbook value, expected db value)}.
    """
    if not MANIFEST.exists():
        return {}
    warnings = json.loads(MANIFEST.read_text()).get("warnings", [])
    line = next((w for w in warnings if "county names corrected" in w), None)
    if not line:
        return {}
    out: dict[tuple[str, str], tuple[str, str]] = {}
    for part in line.split(":", 1)[1].split(";"):
        m = re.search(r"(.+?):\s*'(.*?)'\s*->\s*'(.*?)'", part.strip())
        if m:
            out[(m.group(1).strip(), "property_county")] = (m.group(2), m.group(3))
    return out


def fail(msg: str) -> None:
    failures.append(msg)
    print(f"   FAIL  {msg}")


def env(key: str) -> str | None:
    if os.environ.get(key):
        return os.environ[key]
    envfile = ROOT / ".env"
    if not envfile.exists():
        return None
    for line in envfile.read_text().splitlines():
        line = line.strip()
        if line.startswith(key + "="):
            return line.split("=", 1)[1]
    return None


def slug(col) -> str:
    return re.sub(r"[^a-z0-9]+", "_", str(col).strip().lower()).strip("_")


def norm(v):
    """One canonical form for a value however Excel, JSON or Postgres spells it.

    Excel hands back Timestamps and floats, Postgres dates and Decimals, and
    an empty cell arrives as NaN, None, '' or 'NaT' depending on the path.
    Without this every comparison is a false failure.
    """
    if v is None:
        return None
    if isinstance(v, float) and math.isnan(v):
        return None
    if isinstance(v, pd.Timestamp):
        return v.strftime("%Y-%m-%d")
    if isinstance(v, (dt.datetime, dt.date)):
        return v.strftime("%Y-%m-%d")
    if isinstance(v, bool):
        return v
    if isinstance(v, Decimal):
        f = float(v)
        return float(int(f)) if f == int(f) else round(f, 2)
    if isinstance(v, (int, float)):
        f = float(v)
        return float(int(f)) if f == int(f) else round(f, 2)
    s = str(v).strip()
    if s in ("", "nan", "NaN", "None", "NaT", "-", "N/A"):
        return None
    m = re.match(r"^(\d{4})-(\d{2})-(\d{2})(?:[ T]00:00:00)?$", s)
    if m:
        return f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
    if re.fullmatch(r"[\$,\d.\-]+", s):
        try:
            f = float(s.replace(",", "").replace("$", ""))
            return float(int(f)) if f == int(f) else round(f, 2)
        except ValueError:
            pass
    if s.lower() in ("true", "yes"):
        return True
    if s.lower() in ("false", "no"):
        return False
    return s


def same(a, b) -> bool:
    if a == b:
        return True
    # a cent of rounding between Excel's float and Postgres' numeric
    return (isinstance(a, float) and isinstance(b, float) and abs(a - b) < 0.02)


def table_columns(conn, table: str) -> list[str]:
    cur = conn.execute(f'SELECT * FROM "{table}" LIMIT 0')
    return [d.name for d in cur.description]


def main() -> int:
    quick = "--quick" in sys.argv

    if not WORKBOOK.exists():
        print(f"workbook not found: {WORKBOOK}")
        return 2
    dsn = env("DATABASE_URL_DIRECT")
    if not dsn:
        print("DATABASE_URL_DIRECT not set (looked in env and .env)")
        return 2

    print(f"workbook  {WORKBOOK.name}")
    xl = pd.ExcelFile(WORKBOOK)
    conn = psycopg.connect(dsn, connect_timeout=30)
    conn.execute("SET statement_timeout = '300s'")
    user = conn.execute("SELECT current_user").fetchone()[0]
    print(f"database  connected as {user}\n")

    live = {r[0] for r in conn.execute(
        "SELECT tablename FROM pg_tables WHERE schemaname='public'").fetchall()}

    # ---- 1. row counts ---------------------------------------------------
    print("1. row counts")
    for tab, table in TAB2TABLE.items():
        if tab not in xl.sheet_names:
            fail(f"{tab}: tab missing from workbook")
            continue
        if table not in live:
            fail(f"{table}: table missing from database")
            continue
        n_x = len(xl.parse(tab).dropna(how="all"))
        n_d = conn.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
        if n_x != n_d:
            fail(f"{table}: workbook {n_x} rows, database {n_d}")
    if "deal_economics" in live:
        n_x = len(xl.parse(ECONOMICS_FROM).dropna(how="all"))
        n_d = conn.execute("SELECT count(*) FROM deal_economics").fetchone()[0]
        if n_x != n_d:
            fail(f"deal_economics: {ECONOMICS_FROM} {n_x} rows, database {n_d}")
    print(f"   {len(TAB2TABLE) + 1} tables\n")

    # ---- 2. values -------------------------------------------------------
    if quick:
        print("2. values                                    skipped (--quick)\n")
    else:
        print("2. values")
        corrections = expected_corrections()
        value_maps = expected_value_maps()
        applied: set[tuple[str, str]] = set()
        maps_seen: set[tuple[str, str]] = set()
        cells = diffs = 0
        pairs = list(TAB2TABLE.items()) + [(ECONOMICS_FROM, "deal_economics")]
        for tab, table in pairs:
            if tab not in xl.sheet_names or table not in live:
                continue
            xdf = xl.parse(tab).dropna(how="all")
            xmap = {slug(c): c for c in xdf.columns}
            cur = conn.execute(f'SELECT * FROM "{table}"')
            rows = cur.fetchall()
            dcols = [d.name for d in cur.description]
            drows = [dict(zip(dcols, r)) for r in rows]
            shared = [c for c in dcols if c in xmap and c not in ENVELOPE]
            if not shared or len(xdf) != len(drows):
                continue
            # source_row is the workbook row the export read, so it restores
            # the tab's order however the rows came back from Postgres.
            if "source_row" in dcols:
                drows.sort(key=lambda r: r["source_row"])
            elif "property_key" in dcols and "property_key" in xmap:
                by = {norm(r["property_key"]): r for r in drows}
                drows = [by.get(norm(xdf.iloc[i][xmap["property_key"]]), {})
                         for i in range(len(xdf))]
            t_cells = t_diffs = 0
            for i in range(len(xdf)):
                xr, dr = xdf.iloc[i], drows[i]
                key = (str(xr[xmap["property_key"]]).strip()
                       if "property_key" in xmap else None)
                for c in shared:
                    a, b = norm(xr[xmap[c]]), norm(dr.get(c))
                    t_cells += 1
                    if same(a, b):
                        continue
                    want = corrections.get((key, c))
                    if want and (a, b) == (norm(want[0]), norm(want[1])):
                        applied.add((key, c))
                        continue
                    vmap = value_maps.get((table, c))
                    if vmap and isinstance(a, str) and vmap.get(a) == b:
                        maps_seen.add((table, c))
                        continue
                    t_diffs += 1
                    if t_diffs <= 3:
                        fail(f"{table} row {i} {c}: workbook {a!r}, database {b!r}")
            cells += t_cells
            diffs += t_diffs
            if t_diffs > 3:
                fail(f"{table}: {t_diffs} differing values in total")
        for tc in sorted(set(value_maps) - maps_seen):
            fail(f"{tc[0]}.{tc[1]}: the manifest says this column's values were "
                 f"reconciled with the spine, but the database still matches "
                 f"the workbook")
        missed = set(corrections) - applied
        for key, col in sorted(missed):
            fail(f"{key} {col}: the manifest says this was corrected, "
                 f"but the database still matches the workbook")
        print(f"   {cells:,} cells compared, {diffs} unexplained differences")
        print(f"   {len(applied)} of {len(corrections)} row corrections and "
              f"{len(maps_seen)} of {len(value_maps)} value rewrites present\n")

    # ---- 3. derived columns ----------------------------------------------
    print("3. derived columns")
    # county_code, carried from Deal History, is what corrects three county
    # names the Deal Portfolio tab gets wrong. It has to match its source.
    dh = xl.parse("Deal History").dropna(how="all")
    m = {slug(c): c for c in dh.columns}
    if {"property_key", "county_code"} <= set(m):
        db = {r[0]: r[1] for r in conn.execute(
            "SELECT property_key, county_code FROM deal_portfolio").fetchall()}
        bad = 0
        for _, r in dh.iterrows():
            k, code = str(r[m["property_key"]]).strip(), r[m["county_code"]]
            if k in db and pd.notna(code) and str(code).strip() != str(db[k] or "").strip():
                bad += 1
        if bad:
            fail(f"county_code: {bad} disagree with Deal History")
    # profit_ballpark is Deal History's profit, kept beside the authoritative
    # one so the deals where the two disagree stay visible.
    if {"property_key", "profit"} <= set(m):
        ball: dict[str, float] = {}
        for _, r in dh.iterrows():
            k, p = str(r[m["property_key"]]).strip(), r[m["profit"]]
            if k and pd.notna(p):
                ball.setdefault(k, round(float(p), 2))
        bad = 0
        for k, pb in conn.execute(
                "SELECT property_key, profit_ballpark FROM deal_economics").fetchall():
            exp = ball.get(str(k).strip())
            got = round(float(pb), 2) if pb is not None else None
            if not same(exp, got):
                bad += 1
        if bad:
            fail(f"profit_ballpark: {bad} disagree with Deal History")
    # contract_price is HUD Settlements' sale_price under a name that says
    # what it is: the contract figure, not what the property later sold for.
    h = xl.parse("HUD Settlements").dropna(how="all")
    hm = {slug(c): c for c in h.columns}
    if "sale_price" in hm:
        cur = conn.execute(
            "SELECT contract_price FROM hud_settlements ORDER BY source_row")
        got = [r[0] for r in cur.fetchall()]
        if len(got) == len(h):
            bad = sum(1 for i in range(len(h))
                      if not same(norm(h.iloc[i][hm["sale_price"]]), norm(got[i])))
            if bad:
                fail(f"contract_price: {bad} differ from HUD Settlements sale_price")
    print("   county_code, profit_ballpark, contract_price\n")

    # ---- 4. dropped columns ----------------------------------------------
    print("4. dropped columns")
    kept = 0
    for tab, cols in DROPPED.items():
        d = xl.parse(tab).dropna(how="all")
        dm = {slug(c): c for c in d.columns}
        for c in cols:
            # A name that is not on the tab is not a pass. DROPPED claims these
            # columns exist in the workbook and were left out of the load on
            # purpose; a typo here would otherwise skip the column silently and
            # report success for a check that never ran.
            if c not in dm:
                fail(f"{tab}.{c}: listed as dropped, but no such column on the tab")
                continue
            vals = [norm(v) for v in d[dm[c]]]
            distinct = {str(v) for v in vals if v is not None}
            if len(distinct) > 1:
                fail(f"{tab}.{c}: dropped, but holds {len(distinct)} distinct values")
            kept += 1
    print(f"   {kept} columns confirmed empty or single-valued\n")

    # ---- 5. fill rates ---------------------------------------------------
    print("5. fill rates")
    empty = []
    for table in sorted(EXPECTED_ROLES):
        if table not in live:
            continue
        n = conn.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
        if not n:
            fail(f"{table}: no rows at all")
            continue
        cols = [c for c in table_columns(conn, table) if c not in ENVELOPE]
        sel = ", ".join(f'count("{c}")' for c in cols)
        for c, k in zip(cols, conn.execute(f'SELECT {sel} FROM "{table}"').fetchone()):
            if k == 0:
                empty.append(f"{table}.{c}")
    if empty:
        fail(f"{len(empty)} columns are entirely null: {', '.join(empty[:8])}")
    print("   no column arrived completely null\n")

    # ---- 6. RLS ----------------------------------------------------------
    print("6. row-level security")
    app_dsn = env("DATABASE_URL_APP")
    if not app_dsn:
        fail("DATABASE_URL_APP not set - RLS unverified")
    else:
        try:
            app = psycopg.connect(app_dsn, connect_timeout=30)
        except Exception as exc:                       # noqa: BLE001
            fail(f"cannot connect as the application role: {exc}")
            app = None
        if app is not None:
            bypass = app.execute(
                "SELECT rolbypassrls FROM pg_roles WHERE rolname = current_user"
            ).fetchone()[0]
            if bypass:
                fail("the application role holds BYPASSRLS; every policy is skipped")
            for table, allowed in EXPECTED_ROLES.items():
                if table not in live:
                    continue
                total = conn.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
                for role in EVERYONE:
                    with app.transaction():
                        app.execute("SELECT set_config('app.roles', %s, true)", (role,))
                        n = app.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
                    want = total if role in allowed else 0
                    if n != want:
                        fail(f"{table} as {role}: saw {n} rows, expected {want}")
                # no role set at all must show nothing, not everything
                with app.transaction():
                    app.execute("SELECT set_config('app.roles', '', true)")
                    n = app.execute(f'SELECT count(*) FROM "{table}"').fetchone()[0]
                if n:
                    fail(f"{table} with no role set: saw {n} rows, expected 0")
            for stmt in ("DELETE FROM deal_portfolio",
                         "UPDATE deal_portfolio SET property_city = 'x'",
                         "INSERT INTO deal_portfolio (row_key) VALUES ('x')"):
                try:
                    with app.transaction():
                        app.execute("SELECT set_config('app.roles', 'executive', true)")
                        app.execute(stmt)
                    fail(f"the application role was allowed to: {stmt}")
                except psycopg.errors.InsufficientPrivilege:
                    pass
                except Exception:                      # noqa: BLE001
                    pass
            app.close()
            print(f"   {len(EXPECTED_ROLES)} tables x {len(EVERYONE)} roles, "
                  f"plus no-role and writes\n")
    # ---- 7. joins --------------------------------------------------------
    # Everything above compares the database to the workbook one column at a
    # time, and all of it passed while the chatbot's most obvious join returned
    # zero rows. Values being right is not the same as values lining up.
    print("7. joins")
    # every foreign key indexed, or each join is a sequential scan
    fks = conn.execute("""
        SELECT c.relname, a.attname
        FROM pg_constraint con
        JOIN pg_class c ON c.oid = con.conrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN unnest(con.conkey) k(attnum) ON true
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = k.attnum
        WHERE n.nspname = 'public' AND con.contype = 'f'""").fetchall()
    if not fks:
        fail("no foreign keys declared; nothing enforces the joins")
    for table, col in fks:
        indexed = conn.execute("""
            SELECT count(*) FROM pg_indexes
            WHERE schemaname='public' AND tablename=%s AND indexdef LIKE %s""",
            (table, f"%({col}%")).fetchone()[0]
        if not indexed:
            fail(f"{table}.{col} is a foreign key with no index; every join "
                 f"over it is a sequential scan")
        orphans = conn.execute(f"""
            SELECT count(*) FROM "{table}" t WHERE t.{col} IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM deal_portfolio d
                            WHERE d.property_key = t.{col})""").fetchone()[0]
        if orphans:
            fail(f"{table}: {orphans} rows point at a property that is not in "
                 f"deal_portfolio")
    # categorical columns that appear on more than one table have to agree, or
    # the join silently returns nothing for the values that differ
    for table, col, spine_col in [
            ("deal_aggregates", "deal_source", "deal_source"),
            ("performance_by_exit_strategy", "exit_strategy", "exit_strategy"),
            ("performance_by_county", "county_code", "county_code")]:
        stray = conn.execute(f"""
            SELECT DISTINCT t.{col} FROM "{table}" t
            WHERE t.{col} IS NOT NULL AND NOT EXISTS (
                SELECT 1 FROM deal_portfolio d WHERE d.{spine_col} = t.{col})
            """).fetchall()
        for (v,) in stray:
            fail(f"{table}.{col} = {v!r} matches no row in "
                 f"deal_portfolio.{spine_col}; that join returns nothing")
    # a numeric column typed TEXT loads cleanly and then sorts as a string
    mistyped = []
    for table in sorted(EXPECTED_ROLES):
        if table not in live:
            continue
        cols = conn.execute("""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name=%s AND data_type='text'
            """, (table,)).fetchall()
        for (c,) in cols:
            if c in ENVELOPE or c in TEXT_BY_DESIGN:
                continue
            sql = (f'SELECT count("{c}"), count(*) FILTER '
                   f'(WHERE "{c}" ~ \'^-?[0-9]+(\\.[0-9]+)?$\') '
                   f'FROM "{table}"')
            n, numeric = conn.execute(sql).fetchone()
            if n and n == numeric:
                mistyped.append(f"{table}.{c}")
    for m in mistyped:
        fail(f"{m} is TEXT but every value is a number; ORDER BY will sort it "
             f"as a string and SUM will not work at all")
    print(f"   {len(fks)} foreign keys, 3 categorical columns, "
          f"{len(EXPECTED_ROLES)} tables scanned for mistyped numbers\n")

    conn.close()

    print("=" * 68)
    if failures:
        print(f"{len(failures)} FAILURE(S)")
        return 1
    print("all seven checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
