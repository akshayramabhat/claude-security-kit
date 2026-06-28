-- Test your policies as the unprivileged app role, NEVER as a superuser.
-- Superusers and BYPASSRLS roles skip RLS entirely, so a superuser test passes
-- while production leaks. Run this inside a transaction so it rolls back cleanly.
BEGIN;

-- Become the role your API actually uses.
SET LOCAL ROLE authenticated;

-- Impersonate user A (external-IdP helper variant shown).
SELECT set_config('request.headers', '{"x-user-id":"user_a"}', true);
-- Supabase-native equivalent:
-- SELECT set_config('request.jwt.claims', '{"sub":"user_a"}', true);

-- Expect: only user A's rows.
SELECT count(*) AS user_a_visible_rows FROM your_table;

-- Switch to user B and expect a different, non-overlapping set.
SELECT set_config('request.headers', '{"x-user-id":"user_b"}', true);
SELECT count(*) AS user_b_visible_rows FROM your_table;

-- Expect: zero. An anon caller should see nothing on a user-scoped table.
SET LOCAL ROLE anon;
SELECT count(*) AS anon_visible_rows FROM your_table;

ROLLBACK;
