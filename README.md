# claude-security-kit

Security skills and agents for Claude Code.

## What's inside

- **`security-scan` skill**: runs a layered set of open-source scanners over a
  repo (secrets, SAST, dependency CVEs, container and IaC misconfig, malicious
  packages), then triages the raw output into one prioritized report.
- **`rls-policy-reviewer` agent**: a read-only Postgres Row-Level Security
  auditor that catches missing or broken RLS in migrations before they ship.
- **RLS lockdown kit**: generic RLS policy templates plus a vendor-neutral guide
  to locking down an over-exposed Supabase or Postgres Data API.

## Install

This is a Claude Code plugin. Clone it into your Claude Code plugins directory (or
add it through the plugin or marketplace mechanism your setup uses):

```bash
git clone https://github.com/<user>/claude-security-kit
```

Claude Code auto-discovers `skills/` and `agents/` in the plugin, so once it is on
your plugins path the `/security-scan` skill and the `rls-policy-reviewer` agent
are available.

## Using `security-scan`

Invoke `/security-scan`. The skill will:

1. Detect which ecosystems are present (Python, JS/TS, Docker, IaC).
2. Check which scanners are installed, and list any that are missing with install
   commands. It asks before installing anything.
3. Run the installed, in-scope scanners.
4. Triage and deduplicate the findings, rank them, and write
   `security-scan-report.md` with a Summary, Tools-run, Tools-skipped, Findings,
   and Coverage-gaps section.

### Roster

Core (always run): `gitleaks`, `trufflehog`, `semgrep`, `trivy`, `osv-scanner`.

Language depth (when detected): `pip-audit` and `bandit` for Python; `npm` /
`pnpm` / `yarn audit` for JS/TS.

Supply-chain: `guarddog` (on by default), `hadolint` (on when a Dockerfile
exists).

Opt-in flags: `--scorecard` (OpenSSF Scorecard), `--checkov` (deep IaC),
`--grype` (SBOM-driven SCA).

CodeQL is intentionally not bundled; its license is not OSI open source. The full
roster, install commands, licenses, and rationale are in
`skills/security-scan/reference.md`.

## Prerequisites

The scanners are external binaries you install yourself. The skill checks for them
and offers install commands, but never installs without asking. Each tool keeps
its own license:

| Tool | License |
|---|---|
| gitleaks | MIT |
| trufflehog | AGPL-3.0 |
| semgrep | LGPL-2.1 |
| trivy | Apache-2.0 |
| osv-scanner | Apache-2.0 |
| pip-audit | Apache-2.0 |
| bandit | Apache-2.0 |
| guarddog | Apache-2.0 |
| hadolint | GPL-3.0 |
| OpenSSF Scorecard | Apache-2.0 |
| Checkov | Apache-2.0 |
| Grype / Syft | Apache-2.0 |

## Using the RLS kit

Invoke the `rls-policy-reviewer` agent when migration or SQL files change, before
applying migrations, or when you want a second pair of eyes on data-access safety.
For hands-on lockdown, start with `docs/supabase-data-api-lockdown.md` and the
`templates/rls/` policy shapes.

## Honesty and license

This kit is MIT-licensed. It only invokes installed binaries; it does not
redistribute or link any scanner, so the AGPL, LGPL, and GPL tools above do not
affect its license. Running third-party scanners is itself a small supply-chain
surface, so pin tool versions where you can. A scan is point-in-time and not a
guarantee.
