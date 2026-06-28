# RLS policy templates

Copy-paste Row-Level Security shapes for a Postgres or Supabase backend. Replace
the placeholder names (`your_table`, `parent_table`, `child_table`, `owner_id`,
`parent_id`, `is_active`, `tenant_id`, `deleted_at`) with your own.

If you authenticate with Supabase Auth, use `auth.uid()` directly in policies and
skip the helper. If you authenticate with an external IdP (Clerk, Auth0, custom),
install the helper first so `get_current_user_id()` resolves; otherwise
`auth.uid()` returns NULL and your policies silently fail open or closed. See
`../../docs/supabase-data-api-lockdown.md` for why.

## Practices baked into these templates

- **`FORCE ROW LEVEL SECURITY`** on every table. Without it, an app that connects
  as the table owner bypasses every policy. This is the most common production
  RLS leak.
- **A role on every policy** (`TO authenticated`, `TO anon`, `TO service_role`).
  A policy with no role applies to PUBLIC and is evaluated for every caller.
- **Auth calls wrapped in `(select ...)`** so Postgres evaluates them once per
  query (an initPlan) instead of once per row.
- **Index hints** for the column each policy filters on.

## Files

- `00_helper_get_current_user_id.sql`: the `get_current_user_id()` helper for
  external-IdP setups, with both the header and JWT-claim variants. Apply first.
- `01_user_scoped.sql`: rows owned directly via an owner column. The common case.
- `02_join_scoped.sql`: child rows owned indirectly through a parent table.
- `03_nested.sql`: ownership resolved through a two-level join.
- `04_public_read.sql`: anyone reads active rows, only the service role writes.
- `05_admin_only.sql`: no end-user access, service role manages everything.
- `06_public_insert.sql`: write-only intake (waitlist, contact form). Anyone
  inserts, nobody reads through the API.
- `07_restrictive.sql`: `AS RESTRICTIVE` hard gates (tenant isolation, hiding
  soft-deleted rows) that no permissive policy can widen.
- `verify.sql`: run after applying. Finds tables with RLS off, tables with no
  policies, `USING(true)` policies, per-table policy counts, stray `auth.uid()`
  policies, tables where RLS is enabled but not forced, and policies with no role.
- `test_as_role.sql`: exercise your policies as the unprivileged app role inside
  a rolled-back transaction. Test as the app role, never as a superuser.

## Apply

```bash
psql "$DATABASE_URL" -f 00_helper_get_current_user_id.sql   # external IdP only
psql "$DATABASE_URL" -f 01_user_scoped.sql                  # edit names first
# ... apply the tiers your schema needs ...
psql "$DATABASE_URL" -f verify.sql                          # confirm
psql "$DATABASE_URL" -f test_as_role.sql                    # prove isolation
```
