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

## 2. Check installs, then offer ONE batched install (no silent skips)

Check each in-scope tool with `command -v <tool>`. Split the list into a run-list
(installed) and a missing-list.

If anything is missing, do NOT prompt tool by tool. Pick an installer, disclose,
then offer one install.

**Pick an installer that actually exists.** Do not assume Homebrew or pipx are
present. Detect what is available with `command -v` (brew, pipx, pip3/pip, the
distro manager such as apt-get/dnf/pacman, go, docker). For each missing tool,
choose the best available path from the "One-shot install" guidance in
`reference.md`:

- The Python tools (semgrep, bandit, pip-audit, guarddog) install via pipx on any
  OS. If pipx is missing but Python is present, offer to bootstrap it first with
  `python3 -m pip install --user pipx && pipx ensurepath` (or `brew install pipx`).
- The native tools (gitleaks, trufflehog, trivy, osv-scanner, hadolint) install via
  brew when present, else the distro package, the tool's released binary, or its
  official `docker` image.

If no installer fits a tool on this system, do not fail or guess: report it skipped
with its source link so the user can install it by hand.

**Disclose what you would install.** For every missing tool, show its publisher,
one-line purpose, the exact command that will run, and its audit link (from the
"Publishers and verification" table in `reference.md`). Never pipe a remote script
into a shell (`curl ... | sh`), even if a tool documents one.

**Offer one choice.** Group the missing tools by the installer you chose and
present a single prompt that lets the user run the batched install, run the exact
commands themselves, or install a subset. For example:

> Missing scanners (all open source, installed via brew/pipx):
>   trivy (Aqua Security)  -> brew install trivy   (github.com/aquasecurity/trivy)
>   gitleaks (Gitleaks)    -> brew install gitleaks (github.com/gitleaks/gitleaks)
>   bandit (PyCQA)         -> pipx install bandit   (github.com/PyCQA/bandit)
> Run these for you, paste them to run yourself, or pick a subset? [run / self / pick / skip]

On approval, run only the approved commands, re-check with `command -v`, confirm
each with `<tool> --version`, and move installed tools to the run-list. Never
install without that confirmation, and never silently drop a tool: whatever is
still missing is reported under Tools skipped and Coverage gaps, with its reason
("declined" or "no installer available") and install command from `reference.md`.

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
