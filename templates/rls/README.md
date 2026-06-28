# RLS policy templates

Copy-paste Row-Level Security shapes for a Postgres or Supabase backend. Replace
the placeholder names (`your_table`, `parent_table`, `child_table`, `owner_id`,
`parent_id`, `is_active`) with your own.

If you authenticate with Supabase Auth, use `auth.uid()` directly in policies and
skip the helper. If you authenticate with an external IdP (Clerk, Auth0, custom),
install the helper first so `get_current_user_id()` resolves; otherwise
`auth.uid()` returns NULL and your policies silently fail open or closed. See
`../../docs/supabase-data-api-lockdown.md` for why.

## Files

- `00_helper_get_current_user_id.sql`: the `get_current_user_id()` helper for
  external-IdP setups, with both auth variants documented. Apply this first.
- `01_user_scoped.sql`: rows owned directly via an owner column. The most common
  case.
- `02_join_scoped.sql`: child rows owned indirectly through a parent table.
- `03_nested.sql`: ownership resolved through a two-level join.
- `04_public_read.sql`: anyone reads active rows, only the service role writes.
- `05_admin_only.sql`: no end-user access, service role manages everything.
- `verify.sql`: run after applying. It finds tables with RLS off, tables with no
  policies, `USING(true)` policies, per-table policy counts, and stray
  `auth.uid()` policies that bypass RLS under an external IdP.

## Apply

```bash
psql "$DATABASE_URL" -f 00_helper_get_current_user_id.sql   # external IdP only
psql "$DATABASE_URL" -f 01_user_scoped.sql                  # edit names first
# ... apply the tiers your schema needs ...
psql "$DATABASE_URL" -f verify.sql                          # confirm
```
