-- 1. Protected tables with RLS DISABLED (should be empty):
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public' AND NOT rowsecurity;

-- 2. RLS enabled but NO policies (read-blocked / misconfigured):
SELECT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p
  ON p.tablename = t.tablename AND p.schemaname = t.schemaname
WHERE t.schemaname = 'public' AND t.rowsecurity AND p.policyname IS NULL
GROUP BY t.tablename;

-- 3. USING(true) policies (review each; often a bypass):
SELECT tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public' AND qual = 'true';

-- 4. Policy count per table:
SELECT tablename, count(*) AS policy_count
FROM pg_policies WHERE schemaname = 'public'
GROUP BY tablename ORDER BY tablename;

-- 5. Stray auth.uid() policies (a silent bypass under an external IdP):
SELECT tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public' AND qual ILIKE '%auth.uid()%';
