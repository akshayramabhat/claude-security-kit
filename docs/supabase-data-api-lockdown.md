# Locking down an over-exposed Supabase / Postgres Data API

A Supabase project exposes your Postgres tables over an auto-generated REST API.
Anyone holding the anon key (which ships in your client bundle) can call it. The
only thing standing between that key and full CRUD on a table is Row-Level
Security. If RLS is off, or enabled but misconfigured, the table is an open
database on the public internet.

This guide covers the three ways RLS silently fails and how to lock it down. It
applies to any Postgres backend that derives access from a per-request user
identity, not just Supabase.

## Failure mode 1: permissive public policies

A policy granted to the `public` or `authenticated` role with `USING (true)` or
`WITH CHECK (true)` lets every user touch every row.

Vulnerable:

```sql
CREATE POLICY t_select ON profiles FOR SELECT USING (true);
CREATE POLICY t_insert ON profiles FOR INSERT WITH CHECK (true);
```

Any authenticated user can now read every profile and insert rows as anyone. The
fix is to scope every predicate to the current user:

```sql
CREATE POLICY t_select ON profiles
    FOR SELECT USING (owner_id = get_current_user_id());
CREATE POLICY t_insert ON profiles
    FOR INSERT WITH CHECK (owner_id = get_current_user_id());
```

## Failure mode 2: auth-method mismatch (the silent one)

This is the one that looks fine in review and fails in production. Supabase's
native RLS helper, `auth.uid()`, only returns a value when Supabase Auth issued
the JWT. If you authenticate with an external identity provider (Clerk, Auth0, a
custom token), `auth.uid()` returns NULL.

A policy like `USING (owner_id = auth.uid())` then compares `owner_id` to NULL,
which is never true, so the policy appears to lock everyone out. Teams "fix" the
resulting empty results by adding a permissive fallback policy, and because
multiple PERMISSIVE policies combine with OR (see failure mode 3), the table ends
up wide open.

The fix is a helper that reads the user id your backend sets per request:

```sql
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('request.headers', true)::json->>'x-user-id';
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '';
```

Then write policies against `get_current_user_id()` instead of `auth.uid()`. The
full helper, with both auth variants, is in
`../templates/rls/00_helper_get_current_user_id.sql`.

## Failure mode 3: conflicting PERMISSIVE policies

Postgres combines multiple PERMISSIVE policies on the same command with OR. One
loose policy therefore bypasses every stricter one beside it. Projects accumulate
these when policy files are applied at different times and never reconciled.

The fix is a clean slate: drop all existing policies on the table, then create one
explicit policy per command (SELECT, INSERT, UPDATE, DELETE). Where you need a
hard gate that other policies cannot widen, use a RESTRICTIVE policy
(`AS RESTRICTIVE`), which combines with AND. See
`../templates/rls/07_restrictive.sql`.

## Failure mode 4: the table owner bypasses RLS

Enabling RLS is not enough. By default the table owner, and any role with the
BYPASSRLS attribute, is exempt from every policy. The classic production leak: RLS
is enabled, the policies look correct in review, but the application connects as
the role that owns the tables, so Postgres silently ignores all of them.

Use both fixes:

- Run the application as a non-owner role with no BYPASSRLS attribute.
- Add `ALTER TABLE <t> FORCE ROW LEVEL SECURITY;` so policies apply even to the
  owner. The templates do this on every table.

The Supabase `service_role` key has BYPASSRLS by design, so it always sidesteps
RLS. Keep it server-side and never ship it to a client.

## The access-tier model

Pick the tier that matches how a table is owned, then use the matching template in
`../templates/rls/`:

- User-scoped: rows owned directly via an owner column (`01_user_scoped.sql`).
- Join-scoped: rows owned indirectly through a parent table (`02_join_scoped.sql`).
- Nested: ownership resolved through a two-level join (`03_nested.sql`).
- Public-read: anyone reads active rows, only the service role writes
  (`04_public_read.sql`).
- Admin-only: no end-user access, service role manages everything
  (`05_admin_only.sql`).
- Public-insert: write-only intake like a waitlist or contact form
  (`06_public_insert.sql`).
- Restrictive hard gates: cross-cutting invariants such as tenant isolation or
  hiding soft-deleted rows (`07_restrictive.sql`).

## Performance and correctness

Three habits keep policies both correct and fast:

- **Put a role on every policy** (`TO authenticated`, `TO anon`,
  `TO service_role`). A policy with no role applies to PUBLIC and runs for every
  caller, including ones it was never meant for.
- **Wrap auth calls in a subquery:** `(select auth.uid())` or
  `(select get_current_user_id())`. Postgres then evaluates the call once per
  statement instead of once per row.
- **Index the columns policies filter on** (owner and foreign-key columns). RLS
  turns every query into a filtered one.

## External-IdP integration pattern

For `get_current_user_id()` to resolve, your backend must set the user id on the
database session for each request, inside the same transaction as the query. A
FastAPI-shaped example:

```python
# after you have verified the request's token and extracted user_id
await session.execute(
    text("SELECT set_config('request.headers', :headers, true)"),
    {"headers": json.dumps({"x-user-id": user_id})},
)
# ... run the user's query on the same session/transaction ...
```

The `true` third argument makes the setting local to the transaction, so it does
not leak into the next request on a pooled connection.

## Verification

After applying policies, run `../templates/rls/verify.sql`. It reports:

1. Protected tables with RLS disabled.
2. Tables with RLS enabled but no policies.
3. `USING(true)` policies to review.
4. Policy counts per table.
5. Stray `auth.uid()` policies, which are a silent bypass under an external IdP.
6. Tables where RLS is enabled but not forced (owner bypass).
7. Policies with no role, which apply to PUBLIC.

Then run `../templates/rls/test_as_role.sql` to prove isolation as the actual app
role. Test as that role, never as a superuser, since superusers skip RLS.

## Default-deny checklist

- RLS enabled AND forced (`FORCE ROW LEVEL SECURITY`) on every table that holds
  data, or the app runs as a confirmed non-owner role.
- At least one explicit policy per protected table, one per command.
- A role on every policy (`TO authenticated` / `anon` / `service_role`), never an
  unscoped policy that applies to PUBLIC.
- `WITH CHECK` on every INSERT and UPDATE policy.
- No `USING (true)` on a user-data table.
- Auth calls wrapped in `(select ...)` and the filtered columns indexed.
- Every `SECURITY DEFINER` function sets an explicit `search_path`.
- Service-role key usage minimized, kept server-side, and audited. It bypasses
  RLS entirely.
- The right auth helper for your stack: `auth.uid()` for Supabase-native,
  `get_current_user_id()` for an external IdP. Never mix them by accident.
- Policies tested as the app role with `test_as_role.sql`, never as a superuser.
