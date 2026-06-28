-- Join-scoped: child rows owned indirectly through a parent table.
ALTER TABLE child_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE child_table FORCE ROW LEVEL SECURITY;
-- Index the join column the policies filter on:
-- CREATE INDEX IF NOT EXISTS child_table_parent_idx ON child_table (parent_id);

CREATE POLICY child_table_select ON child_table
    FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY child_table_insert ON child_table
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY child_table_update ON child_table
    FOR UPDATE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = (select get_current_user_id())))
    WITH CHECK (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY child_table_delete ON child_table
    FOR DELETE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = (select get_current_user_id())));
