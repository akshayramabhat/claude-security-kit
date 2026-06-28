-- Nested: ownership resolved through a two-level join (grandchild -> child -> parent).
ALTER TABLE grandchild_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE grandchild_table FORCE ROW LEVEL SECURITY;
-- Index the join column the policies filter on:
-- CREATE INDEX IF NOT EXISTS grandchild_child_idx ON grandchild_table (child_id);

CREATE POLICY grandchild_select ON grandchild_table
    FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY grandchild_insert ON grandchild_table
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY grandchild_update ON grandchild_table
    FOR UPDATE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = (select get_current_user_id())))
    WITH CHECK (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = (select get_current_user_id())));

CREATE POLICY grandchild_delete ON grandchild_table
    FOR DELETE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM child_table
                JOIN parent_table ON parent_table.id = child_table.parent_id
                WHERE child_table.id = grandchild_table.child_id
                AND parent_table.owner_id = (select get_current_user_id())));
