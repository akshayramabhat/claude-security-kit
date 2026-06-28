-- Join-scoped: child rows owned indirectly through a parent table.
ALTER TABLE child_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY child_table_select ON child_table
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = get_current_user_id()));

CREATE POLICY child_table_insert ON child_table
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = get_current_user_id()));

CREATE POLICY child_table_update ON child_table
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = get_current_user_id()))
              WITH CHECK (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = get_current_user_id()));

CREATE POLICY child_table_delete ON child_table
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM parent_table
                WHERE parent_table.id = child_table.parent_id
                AND parent_table.owner_id = get_current_user_id()));
