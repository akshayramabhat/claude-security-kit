# Changelog

## 0.1.1 - 2026-06-28

- `security-scan` first run now offers to install all missing scanners in one
  batched, single-confirmation step (grouped by package manager) instead of
  prompting tool by tool. Nothing installs without that one confirmation.

## 0.1.0 - 2026-06-28

Initial release.

- `security-scan` skill that orchestrates open-source scanners (gitleaks,
  trufflehog, semgrep, trivy, osv-scanner, pip-audit, bandit, guarddog, hadolint)
  and triages the output into one prioritized report, with opt-in flags for
  OpenSSF Scorecard, Checkov, and Grype+Syft.
- `rls-policy-reviewer` agent for auditing Postgres Row-Level Security.
- `templates/rls/` policy shapes (five ownership tiers) plus `verify.sql`.
- `docs/supabase-data-api-lockdown.md` vendor-neutral lockdown guide.
