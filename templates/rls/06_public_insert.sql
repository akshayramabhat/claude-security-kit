-- Public-insert: anyone may insert (a waitlist, contact form, signup) but nobody
-- may read, update, or delete through the API. This is the safe shape for a
-- write-only intake table: a leak of the anon key cannot dump what was collected.
ALTER TABLE signups ENABLE ROW LEVEL SECURITY;
ALTER TABLE signups FORCE ROW LEVEL SECURITY;

CREATE POLICY signups_insert ON signups
    FOR INSERT TO anon, authenticated
    WITH CHECK (true);

-- No SELECT/UPDATE/DELETE policy for anon/authenticated means those are denied.
-- Read the collected rows with the service_role key (it bypasses RLS), or add an
-- explicit service_role policy if you read from a non-BYPASSRLS role:
CREATE POLICY signups_service_read ON signups
    FOR SELECT TO service_role
    USING (true);
