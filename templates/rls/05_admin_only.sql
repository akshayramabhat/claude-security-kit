-- Admin-only: no end-user access; service role manages everything.
ALTER TABLE config_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY config_table_admin ON config_table
    FOR ALL USING (auth.role() = 'service_role');
