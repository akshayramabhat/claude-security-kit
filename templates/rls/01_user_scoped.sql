-- User-scoped: rows owned directly via an owner column.
-- Swap get_current_user_id() for auth.uid() if you use Supabase-native auth.
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY your_table_select ON your_table
    FOR SELECT USING (owner_id = get_current_user_id());

CREATE POLICY your_table_insert ON your_table
    FOR INSERT WITH CHECK (owner_id = get_current_user_id());

CREATE POLICY your_table_update ON your_table
    FOR UPDATE USING (owner_id = get_current_user_id())
               WITH CHECK (owner_id = get_current_user_id());

CREATE POLICY your_table_delete ON your_table
    FOR DELETE USING (owner_id = get_current_user_id());
