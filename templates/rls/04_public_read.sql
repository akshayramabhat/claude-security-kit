-- Public-read: anyone may read active rows; only the service role writes.
ALTER TABLE public_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_table FORCE ROW LEVEL SECURITY;

CREATE POLICY public_table_select ON public_table
    FOR SELECT TO anon, authenticated
    USING (is_active = true);

-- The service_role key has BYPASSRLS, so it can already write. This explicit
-- policy is only needed if you manage rows from a role that is NOT BYPASSRLS.
CREATE POLICY public_table_service_write ON public_table
    FOR ALL TO service_role
    USING (true) WITH CHECK (true);
