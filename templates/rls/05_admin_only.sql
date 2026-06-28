-- Admin-only: no end-user (anon/authenticated) access. With RLS enabled and no
-- policy granting those roles, they are denied by default. The service_role key
-- has BYPASSRLS and manages the table; the explicit policy below is only needed
-- if you manage it from a non-BYPASSRLS role.
ALTER TABLE config_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE config_table FORCE ROW LEVEL SECURITY;

CREATE POLICY config_table_service_only ON config_table
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);
