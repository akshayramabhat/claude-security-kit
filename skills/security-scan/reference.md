# security-scan reference

The roster the `security-scan` skill runs, with install commands, licenses, and
the rationale for what is in and out. The skill reads this file at run time.

## Core (always run, language-agnostic)

| Tool | Surface | License | Install | Run |
|---|---|---|---|---|
| gitleaks | secrets + git history | MIT | `brew install gitleaks` | `gitleaks detect --no-banner --redact` |
| trufflehog | secrets with live verification | AGPL-3.0 | `brew install trufflehog` | `trufflehog filesystem . --only-verified` |
| semgrep | multi-language SAST (CE, 3000+ rules) | LGPL-2.1 | `brew install semgrep` or `pipx install semgrep` | `semgrep scan --config auto` |
| trivy | dep CVEs + images + IaC misconfig + licenses + SBOM | Apache-2.0 | `brew install trivy` | `trivy fs --scanners vuln,misconfig,secret,license .` |
| osv-scanner | lockfile CVEs via Google OSV | Apache-2.0 | `brew install osv-scanner` | `osv-scanner scan source -r .` |

trufflehog and gitleaks are complementary: gitleaks is fast and broad, trufflehog
verifies that a found secret is still live. Group secrets findings by verified
(trufflehog) vs unverified (gitleaks) in the report.

## Language depth (run when the ecosystem is detected)

| Tool | Surface | License | Install | Run |
|---|---|---|---|---|
| pip-audit | Python deps (PyPA) | Apache-2.0 | `pipx install pip-audit` | `pip-audit` |
| bandit | Python-specific SAST idioms | Apache-2.0 | `pipx install bandit` | `bandit -r . -ll` |
| npm/pnpm/yarn audit | JS/TS registry advisories | bundled | (with the toolchain) | `npm audit` / `pnpm audit` / `yarn npm audit` |

Pick the JS audit command by the lockfile present: `package-lock.json` -> npm,
`pnpm-lock.yaml` -> pnpm, `yarn.lock` -> yarn.

## Supply-chain hardening

| Tool | Surface | License | Default | Install | Run |
|---|---|---|---|---|---|
| GuardDog (Datadog) | malicious / typosquatted PyPI, npm, Go packages | Apache-2.0 | ON | `pipx install guarddog` | `guarddog pypi scan .` and/or `guarddog npm scan .` |
| hadolint | Dockerfile security/lint | GPL-3.0 | ON, only when a Dockerfile exists | `brew install hadolint` | `hadolint Dockerfile` |

GuardDog catches a class the CVE scanners miss: the dependency itself is hostile
(install-script exfiltration, obfuscation, typosquatting), not merely "has a
known CVE."

## Opt-in flags (off by default)

| Flag | Tool | Surface | License | Notes |
|---|---|---|---|---|
| `--scorecard` | OpenSSF Scorecard | repo + dependency upstream posture | Apache-2.0 | networked; best with `GITHUB_AUTH_TOKEN` |
| `--checkov` | Checkov | deep Terraform/CFN/K8s IaC policy | Apache-2.0 | for IaC-heavy repos |
| `--grype` | Grype + Syft | SBOM-driven SCA | Apache-2.0 | alternative to Trivy SCA; expect overlapping findings |

## One-shot install (batched, for the skill's single prompt)

Do not assume Homebrew or pipx exist. Detect installers first (brew, pipx, pip, the
distro manager, go, docker), then group the missing tools by the installer you will
actually use and offer one combined install.

Preferred groupings when brew and pipx are both present:

- Homebrew: `brew install gitleaks trufflehog semgrep trivy osv-scanner hadolint`
- pipx: `pipx install bandit pip-audit guarddog`
- Opt-in additions: Scorecard via `brew install scorecard`, Checkov via
  `pipx install checkov`, Grype + Syft via `brew install grype syft`.

When a manager is missing:

- No pipx but Python present: bootstrap with
  `python3 -m pip install --user pipx && pipx ensurepath` (or `brew install pipx`).
  semgrep, bandit, pip-audit, and guarddog are pure-Python and install via pipx on
  any OS.
- No Homebrew (common on Linux): for the native tools use the distro package
  (apt/dnf/pacman), the tool's released binary from its source repo, or its
  official Docker image. Aqua (trivy), Truffle Security (trufflehog), hadolint, and
  semgrep all publish images, so `docker run` works when nothing else is available.

Heavier dependency to watch: guarddog pulls `pygit2`, which compiles against the
`libgit2` C library. If `pipx install guarddog` fails to build pygit2, install
libgit2 first (`brew install libgit2`, or `libgit2-dev` on Debian/Ubuntu) and
retry, or use guarddog's Docker image. Do not silently install libgit2 as part of
the guarddog install; surface it as its own step. guarddog is optional.

Only install the tools that are actually in scope and missing.

## Publishers and verification

Install scanners only through the user's existing package managers (Homebrew,
pipx), which fetch from official sources and verify integrity. Never pipe a remote
script into a shell (`curl ... | sh`). After install, confirm each tool with
`<tool> --version`. Every tool is open source; here is who publishes each and where
to audit it:

| Tool | Publisher | Source |
|---|---|---|
| gitleaks | Gitleaks | github.com/gitleaks/gitleaks |
| trufflehog | Truffle Security | github.com/trufflesecurity/trufflehog |
| semgrep | Semgrep, Inc. | github.com/semgrep/semgrep |
| trivy | Aqua Security | github.com/aquasecurity/trivy |
| osv-scanner | Google (OSV) | github.com/google/osv-scanner |
| pip-audit | PyPA | github.com/pypa/pip-audit |
| bandit | PyCQA | github.com/PyCQA/bandit |
| guarddog | Datadog | github.com/DataDog/guarddog |
| hadolint | hadolint | github.com/hadolint/hadolint |
| OpenSSF Scorecard | OpenSSF | github.com/ossf/scorecard |
| Checkov | Prisma Cloud (Bridgecrew) | github.com/bridgecrewio/checkov |
| Grype / Syft | Anchore | github.com/anchore/grype |

## Deliberately excluded (with rationale)

- **CodeQL**: not OSI open source; its license restricts automated analysis to
  open-source, academic, and personal use. Do not bundle or auto-run it. Pointer
  only: if your repo is public, enable GitHub's free CodeQL Action in CI.
- **safety**: overlaps pip-audit, which is free and PyPA-official.
- **OWASP Dependency-Check**: slow NVD download, Java-centric, high false
  positives next to osv-scanner and trivy.
- **Falco**: runtime security, not static repo scanning. Out of scope.

## Supply-chain hygiene note (include in every report)

Running third-party scanners is itself a small supply-chain surface. A scanner's
own database feed was implicated in a 2026 CERT-EU breach. Prefer pinned tool
versions and verify checksums where the installer supports it. Report the
resolved version of each tool that runs.

## License note

This kit only invokes installed binaries. It does not redistribute or link any
of these tools, so the AGPL, LGPL, and GPL tools above do not affect the kit's
own MIT license. Anyone running the kit installs the tools themselves and is
subject to each tool's license.
