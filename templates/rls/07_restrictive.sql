-- RESTRICTIVE policies combine with AND, so they are a hard gate that no
-- PERMISSIVE policy can widen. Use them for cross-cutting invariants that must
-- hold no matter what other policies a table accumulates. The PERMISSIVE tiers
-- (01-06) grant access; these RESTRICTIVE policies subtract from it.
--
-- A table's effective rule becomes:
--   (any PERMISSIVE policy passes) AND (every RESTRICTIVE policy passes)

-- Example 1: tenant isolation. Even if a per-row policy is too broad, no row
-- outside the caller's tenant is ever visible. `current_tenant_id()` is a helper
-- you define the same way as get_current_user_id().
CREATE POLICY tenant_isolation ON your_table
    AS RESTRICTIVE
    FOR ALL TO authenticated
    USING (tenant_id = (select current_tenant_id()));

-- Example 2: never expose soft-deleted rows through the API, regardless of which
-- read policy matched.
CREATE POLICY hide_soft_deleted ON your_table
    AS RESTRICTIVE
    FOR SELECT TO anon, authenticated
    USING (deleted_at IS NULL);
