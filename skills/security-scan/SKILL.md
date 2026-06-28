---
name: security-scan
description: Run a layered open-source security scan (secrets, SAST, dependency CVEs, container/IaC, malicious packages) over the current repo and produce a prioritized, triaged report. Use when the user asks to security-scan, audit, find vulnerabilities/CVEs, or check for leaked secrets in a codebase.
---

# security-scan

Orchestrate a set of open-source security scanners over the current repository,
then triage their raw output into one prioritized, honest report. The tool roster,
install commands, licenses, and exclusions live in `reference.md` next to this
file. Read it before you start.

Run the procedure below in order. Do not skip steps. Never claim a repo is clean
when tools were skipped.

## 1. Detect

Determine the scan target (default: the current repo root, or a path the user
gave) and which ecosystems are present:

- Python if any of `pyproject.toml`, `requirements*.txt`, `setup.py`, `setup.cfg`.
- JS/TS if `package.json`. Pick the audit command by lockfile: `package-lock.json`
  to npm, `pnpm-lock.yaml` to pnpm, `yarn.lock` to yarn.
- Dockerfile present enables hadolint.
- Honor opt-in flags if the user passed them: `--scorecard`, `--checkov`, `--grype`.

Build the in-scope tool list: the core five always, plus the language-depth tools
for each detected ecosystem, plus GuardDog, plus hadolint when a Dockerfile
exists, plus any opt-in tools requested.

## 2. Check installs (no silent skips)

For each in-scope tool, check it is on PATH with `command -v <tool>`. Split the
list into a run-list (installed) and a skipped-list (missing). For every skipped
tool, record the reason ("not installed") and its install command from
`reference.md`. Offer to install the missing tools, but ask the user before
running any install command. Never silently drop a tool.

## 3. Pin and note

For each tool that will run, capture its resolved version (`<tool> --version`).
Include the supply-chain hygiene note from `reference.md` in the report, and
prefer pinned versions where the user controls installation.

## 4. Run

Run each in-scope, installed scanner from the scan target using the exact commands
in `reference.md`. Capture stdout and stderr for each. If a tool errors, that is
itself a reported result; do not silently drop it.

## 5. Triage

Merge findings across tools and make them useful:

- Deduplicate: collapse the same file+line+rule, and the same CVE reported by more
  than one SCA tool, into one entry that lists which tools flagged it.
- Rank by severity times exploitability, most urgent first.
- For each finding give: tool, location, severity, a one-line reason it matters, a
  concrete fix, and a confidence or false-positive note.
- Group secrets findings by verified (trufflehog `--only-verified`) vs unverified
  (gitleaks). Verified secrets are top priority.

## 6. Report

Write `security-scan-report.md` to the scan target root with these sections:

- `## Summary`: counts by severity, and a one-line verdict.
- `## Tools run`: each tool with its resolved version.
- `## Tools skipped`: each skipped tool, the reason, and its install command.
- `## Findings`: the ranked, deduplicated list from step 5.
- `## Coverage gaps`: what did not run and what that leaves unchecked.

Echo the Summary and the Tools-skipped list to the terminal.

## 7. Honesty rules

- Never write "no vulnerabilities found" if any tool was skipped. Write "no
  findings from the tools that ran" and list the coverage gaps.
- State that this is a point-in-time scan with open-source tools, not a
  guarantee, and that running scanners is itself a small supply-chain surface.
