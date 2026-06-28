-- Nested: ownership resolved through a two-level join (grandchild -> child -> parent).
ALTER TABLE grandchild_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY grandchild_select ON grandchild_table
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = get_current_user_id()));

CREATE POLICY grandchild_insert ON grandchild_table
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = get_current_user_id()));

CREATE POLICY grandchild_delete ON grandchild_table
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = get_current_user_id()));
