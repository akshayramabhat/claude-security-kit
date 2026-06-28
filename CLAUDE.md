# claude-security-kit

This repo is a Claude Code plugin. It provides:

- **`skills/security-scan/`**: a skill that orchestrates open-source security
  scanners over the current repo and writes `security-scan-report.md`. The roster,
  install commands, and licenses are in `skills/security-scan/reference.md`. Read
  that file before running the skill.
- **`agents/rls-policy-reviewer.md`**: a read-only Postgres RLS auditor agent.
- **`templates/rls/`** and **`docs/supabase-data-api-lockdown.md`**: the RLS
  lockdown kit the agent references.

## Behavior the skill must keep

- Never install a scanner without asking the user first.
- Never report "no vulnerabilities" when a tool was skipped. Report what ran, what
  was skipped and why, and the resulting coverage gaps.
- Report the resolved version of each tool that runs, and prefer pinned versions.

## House style for docs

User-facing copy in this repo avoids em dashes and AI-sounding filler, and states
tool limitations plainly. Keep that voice in any README or doc changes.
