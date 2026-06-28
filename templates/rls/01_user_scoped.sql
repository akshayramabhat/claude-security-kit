-- User-scoped: rows owned directly via an owner column.
--
-- Swap get_current_user_id() for auth.uid() if you use Supabase-native auth.
-- The (select ...) wrapper makes Postgres evaluate the auth call once per query
-- (an initPlan) instead of once per row.
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;
-- FORCE applies RLS even to the table owner. Keep it unless you are certain your
-- app connects as a non-owner role; without it, an app that owns the table
-- bypasses every policy below.
ALTER TABLE your_table FORCE ROW LEVEL SECURITY;
-- Index the column the policies filter on, or RLS will scan on large tables:
-- CREATE INDEX IF NOT EXISTS your_table_owner_idx ON your_table (owner_id);

CREATE POLICY your_table_select ON your_table
    FOR SELECT TO authenticated
    USING (owner_id = (select get_current_user_id()));

CREATE POLICY your_table_insert ON your_table
    FOR INSERT TO authenticated
    WITH CHECK (owner_id = (select get_current_user_id()));

CREATE POLICY your_table_update ON your_table
    FOR UPDATE TO authenticated
    USING (owner_id = (select get_current_user_id()))
    WITH CHECK (owner_id = (select get_current_user_id()));

CREATE POLICY your_table_delete ON your_table
    FOR DELETE TO authenticated
    USING (owner_id = (select get_current_user_id()));
