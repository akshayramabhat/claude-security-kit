# Contributing

Issues and PRs welcome.

## Adding a scanner to the roster

The bar for a new scanner is that it covers a surface the current roster does not,
without flooding triage with duplicate findings. If it overlaps an existing tool,
make the case for why both earn their place. Add it to
`skills/security-scan/reference.md` with its surface, install command, license,
and default-on or opt-in status, then reference it from the skill.

## Keep the kit honest

- The skill asks before installing anything.
- It never claims a clean result when a tool was skipped.
- It states that a scan is point-in-time, not a guarantee.

A PR that weakens any of those will be declined.

## Validate locally

```bash
python -c "import json; json.load(open('.claude-plugin/plugin.json'))"
# structural SQL check
python - <<'PY'
import glob
for f in sorted(glob.glob("templates/rls/*.sql")):
    code = "\n".join(l for l in open(f) if not l.strip().startswith("--"))
    assert code.count("(") == code.count(")"), f
    assert code.strip().endswith(";"), f
print("ok")
PY
```

## Docs voice

User-facing copy avoids em dashes and AI-sounding filler, and states limitations
plainly.
