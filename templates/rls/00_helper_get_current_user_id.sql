-- Variant A: Supabase-native auth. Supabase Auth issues the JWT, so use
-- auth.uid() directly in policies and you do NOT need this helper:
--   USING (owner_id = (select auth.uid()))
--
-- Variant B: external IdP (Clerk, Auth0, custom). auth.uid() returns NULL, so
-- policies that use it silently pass for nobody and the table looks empty, OR
-- (combined with a permissive policy) wide open. Define a helper that reads the
-- user id your backend sets per request. Your backend MUST run, per request:
--   SELECT set_config('request.headers', '{"x-user-id":"<id>"}', true);
-- The `true` makes it transaction-local, which is required behind a transaction
-- pooler (PgBouncer/Supavisor); a session-wide SET would leak across requests.
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('request.headers', true)::json->>'x-user-id';
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '';

-- Variant B (JWT claim): if your IdP's user id is in the JWT `sub` claim and the
-- token reaches Postgres (e.g. Supabase third-party auth), read it from the
-- claims instead of a custom header:
--   RETURN current_setting('request.jwt.claims', true)::json->>'sub';
--
-- In every policy, call the helper WRAPPED in a subquery: (select
-- get_current_user_id()). Postgres then evaluates it once per statement (an
-- initPlan) instead of once per row, which is the single biggest RLS speedup.
