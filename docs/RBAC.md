# Access control

## The six roles

| Role | Reads |
|---|---|
| `executive` | Everything. |
| `acquisitions` | Acquisition, property, comparable sales, deal and relevant financial data. |
| `construction` | Projects, scopes, contractors, vendors, budgets, historical construction costs. |
| `property_management` | Rentals, tenants, maintenance, property information. |
| `accounting` | Authorised financial and accounting information. |
| `va` | Only what a specific responsibility requires. |

## What each actually sees

Measured against the loaded data:

| Role | Deal rows | Passage rows | Tables | Margin fields |
|---|---:|---:|---:|---|
| executive | 5,279 | 4,948 | 16 | yes |
| accounting | 5,048 | 4,861 | 12 | yes |
| acquisitions | 4,661 | 4,617 | 10 | yes |
| construction | 3,792 | 1,776 | 4 | ARV only |
| property_management | 377 | 1,776 | 3 | cash-in only |
| **va** | **372** | **1,776** | **2** | **none** |

## Failing closed

Three ways a request can arrive without a usable scope, and all three return
nothing rather than everything:

- `app.roles` never set — `current_setting` returns NULL, the array overlap
  returns NULL, the row is excluded.
- `app.roles` set to an empty string — the array is `{''}`, which overlaps
  nothing.
- an unrecognised role — no row lists it.

Once the passages move into Postgres (2026-09-13 decision), all three apply
to them as well — the scope stops being something application code has to
remember and becomes something the database refuses to ignore.

## The rule that is easiest to break

`allowed_roles` is set from the verified token. It is never read from a
header, a query parameter or a request body, and the scoped helpers refuse a
query that tries to set it — a caller must not be able to widen its own
scope.
