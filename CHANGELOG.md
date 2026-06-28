# Changelog

## 0.1.3 - 2026-06-28

- The install step no longer assumes Homebrew or pipx. It detects the available
  package managers (brew, pipx, pip, distro, go, docker), bootstraps pipx via pip
  when it is missing, and falls back to distro packages, released binaries, or
  official Docker images when Homebrew is absent. A tool with no available
  installer is reported as skipped instead of failing silently.

## 0.1.2 - 2026-06-28

- Before installing any scanner, `security-scan` now discloses what it would
  install: each tool's publisher, the exact `brew`/`pipx` command, and a link to
  its source to audit. Installs only via the user's package managers (never
  `curl | sh`), and the user can run the commands themselves instead. Added a
  "Publishers and verification" table to the scanner reference.

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
