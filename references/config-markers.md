# Plan target detection markers

Used by `scripts/detect-plan-target.sh` and manual fallback.

## AGENTS.md patterns

```bash
grep -nE 'plans/NNN|开计划|写计划|Plan 协议|plan-handoff|plansDirectory' AGENTS.md 2>/dev/null
```

Common signals:

- `plans/NNN-<主题>.md` or `plans/NNN-*.md`
- § "开计划" / "Plan 协议" / §3.0
- Explicit forbid: host temp plan mode as primary storage

Default root when AGENTS mentions `plans/` but no alternate path: **`plans/`**

## plans/README.md

If present, plan root is the directory containing README (usually `plans/`).

## Claude Code

```bash
python3 -c "
import json, pathlib
p = pathlib.Path('.claude/settings.json')
print(json.loads(p.read_text()).get('plansDirectory','')) if p.exists() else print('')
"
```

Relative paths are from repo root.

## Existing activity

```bash
ls plans/[0-9]*.md plans/done/[0-9]*.md 2>/dev/null | head -3
```

If files exist, root is `plans/` even without AGENTS.

## Bootstrap threshold

Bootstrap when **all** are false:

- AGENTS.md plan section
- `plans/README.md`
- `plans/[0-9]*.md` or `plans/done/`
- `.claude/settings.json` with `plansDirectory`

Bootstrap creates `plans/`, `plans/done/`, minimal `plans/README.md`, optional `.claude/settings.json` merge.
