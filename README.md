# plan-handoff

Lightweight agent skill: **force plan mode output from session memory onto a git-tracked file**.

Plan mode is scratch space. Handoff is the contract for the next session, agent, or human.

## Scope

| In scope | Out of scope |
|----------|--------------|
| Detect / bootstrap `plans/` (or project-specific plan root) | Writing high-quality implementation plans |
| Proxy Cursor / Claude Code / Qoder plan mode → repo file | Task breakdown, review lenses, TDD |
| Minimal handoff template | Depends on `writing-plans`, `grilling`, etc. |

Compose with other skills in [loop-engineering](https://github.com/wind8ai/loop-engineering-startup) loops — no mutual imports.

## Install

**Single repo (symlink or copy):**

```bash
# Cursor / cross-agent
mkdir -p .agents/skills
ln -sfn /path/to/plan-handoff .agents/skills/plan-handoff

# Claude Code
mkdir -p .claude/skills
ln -sfn /path/to/plan-handoff .claude/skills/plan-handoff
```

**Via loop-engineering mono repo:**

```bash
./scripts/link-skills.sh --target /path/to/project --skills plan-handoff --claude
```

## Trigger phrases

写计划 · 开 plan · plan 一下 · 规划 · 落 plan · plan handoff · 交接 plan

## Layout

```
plan-handoff/
├── SKILL.md
├── references/
│   ├── hosts.md
│   └── config-markers.md
└── scripts/
    └── detect-plan-target.sh
```

## License

MIT
