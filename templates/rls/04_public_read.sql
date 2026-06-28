-- Public-read: anyone may read active rows; only the service role may write.
ALTER TABLE public_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY public_table_select ON public_table
    FOR SELECT USING (is_active = true);

CREATE POLICY public_table_admin_all ON public_table
    FOR ALL USING (auth.role() = 'service_role');
