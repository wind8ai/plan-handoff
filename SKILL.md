---
name: plan-handoff
description: >-
  Force coding-agent plan mode output from session memory onto a git-tracked
  file in the repo. Detects or bootstraps plan directory config (AGENTS.md,
  plans/, Claude plansDirectory). Use when the user says 写计划, 开 plan, plan 一下,
  规划, 落 plan, handoff plan, or when plan mode would otherwise stay in host
  temp storage (~/.cursor/plans/, session-only drafts). Does not write or
  decompose plans — pair with writing-plans, grilling, or planning-and-task-breakdown.
version: 0.1.0
license: MIT
---

# Plan Handoff

**One job:** session plan → repo file. Nothing else.

Plan mode is for thinking. **Handoff** is for persistence — so the next session, another agent, or a human can continue without re-deriving context.

This skill does **not** decide plan quality, task breakdown, or review. Load other skills for that. This skill only ensures the plan **lands on disk** in the right place.

## When to use

**Use when any of these are true:**

- User trigger words: 写计划 / 写 plan / 开 plan / plan 一下 / 规划一下 / 落 plan / plan handoff / 交接 plan
- You are in (or about to enter) host plan mode and output would stay in session or host temp dirs
- User asks to make a plan "handoff-ready" or "so another agent can pick it up"
- You finished plan-mode exploration and have not yet written a repo file

**Do not use for:**

- Executing an existing plan (read `plans/NNN-*.md` and implement)
- Writing plan content from scratch with no plan-mode phase (use `writing-plans` or project SDD skills)
- Single-line typo fixes that need no plan file

## Hard rules

1. **Repo file is the source of truth.** Host temp plan storage is scratch only.
2. **MUST NOT** end a plan session with conclusions only in chat or host temp paths:
   - `~/.cursor/plans/`
   - `~/.claude/plans/` (random filenames)
   - Any path outside the project git tree
3. **MUST** write (or update) a file under the detected plan root before switching to agent/implement mode or stopping.
4. **MUST NOT** import or require other skills. Optional composition only (e.g. load `grilling` before handoff, `writing-plans` after — user's choice).
5. If plan mode was used for exploration, **flush** conclusions into the repo file — do not ask the user to copy-paste from chat.

## Process

### Step 1 — Detect plan target

Run detection (or read markers manually):

```bash
bash scripts/detect-plan-target.sh
```

Read in order until a plan root is resolved:

| Priority | Marker | Plan root |
|----------|--------|-----------|
| 1 | `AGENTS.md` — § Plan / §3.0 / "开计划" / `plans/NNN` | Path named in AGENTS (default `plans/`) |
| 2 | `plans/README.md` | `plans/` |
| 3 | `.claude/settings.json` → `plansDirectory` | Value relative to repo root |
| 4 | Existing `plans/[0-9]*.md` or `plans/done/` | `plans/` |
| 5 | No markers | **Bootstrap** (Step 2) then `plans/` |

See [references/config-markers.md](references/config-markers.md) for grep patterns.

**Filename convention** (unless AGENTS overrides):

- Active: `plans/NNN-<kebab-topic>.md` (three-digit increment)
- Done: `plans/done/NNN-<kebab-topic>.md`

Next number:

```bash
ls plans/done/ plans/[0-9]*.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1
# last + 1, zero-pad to 3 digits; if none, use 001
```

### Step 2 — Bootstrap (only if Step 1 found nothing)

Create minimal layout — do not invent project-specific plan methodology:

```
plans/
├── README.md    # pointer: "Plan files live here; see AGENTS.md when added"
└── done/
```

If Claude Code is used in this repo, add or merge:

```json
{
  "plansDirectory": "./plans"
}
```

into `.claude/settings.json`.

Optionally append a short § Plan handoff stub to `AGENTS.md` (3–5 lines: trigger words + `plans/NNN-*.md` + archive to `plans/done/`). **Do not** rewrite existing AGENTS content.

Re-run `detect-plan-target.sh` and confirm `PLAN_ROOT=plans`.

### Step 3 — Host plan mode (optional scratch)

Use host plan mode for exploration if it helps. See [references/hosts.md](references/hosts.md).

| Host | Enter plan | Temp storage (scratch only) |
|------|------------|----------------------------|
| Cursor | `--plan`, `--mode plan`, Shift+Tab Plan | `~/.cursor/plans/` |
| Claude Code | `--permission-mode plan`, EnterPlanMode | Routed via `plansDirectory` — still use `NNN-*.md` naming |
| Qoder | `/plan` toggle | Session / host temp |

**While in plan mode:** take notes freely. **Before exit:** all decisions that matter for handoff go into the repo file.

### Step 4 — Handoff write (required)

Write or update the target file. Minimum viable handoff:

```markdown
# Plan NNN — <topic>

> Status: 📋 Draft
> Handoff: <ISO date> via plan-handoff
> Host: Cursor | Claude Code | Qoder | other

## Context
<Why this plan exists — enough for a zero-context reader>

## Decisions
<What was decided in plan mode — bullet list>

## Open questions
<Unresolved items, or "none">

## Next
<What the implementer should do first — one line minimum>
```

**Content policy:** paste/plan-mode synthesis is fine. Deep task breakdown is **optional** — that belongs in `writing-plans` / `planning-and-task-breakdown` if the user wants it later.

**Updating an existing plan:** edit the same `plans/NNN-*.md`; add a `> Handoff:` line or short changelog under Context.

### Step 5 — Verify handoff

Before leaving plan mode or ending the turn:

```bash
test -f plans/NNN-*.md   # or exact path from detection
git status -- plans/
```

Confirm:

- [ ] File exists under git-tracked plan root
- [ ] No critical content remains only in chat or `~/.cursor/plans/`
- [ ] Status line present
- [ ] Paths in the file are repo-relative (no `/Users/...`)

Tell the user: **handoff path**, **plan number**, and whether they should commit now or continue editing.

## Composition (optional, not required)

| Phase | Example skills | Role |
|-------|----------------|------|
| Before plan mode | `grilling`, `brainstorming` | Align scope |
| Plan mode | *(host native)* | Explore |
| **Handoff** | **`plan-handoff`** | **Persist to repo** |
| After handoff | `writing-plans`, `planning-and-task-breakdown` | Expand tasks / quality |
| Execute | `executing-plans`, project loops | Implement |

## Anti-patterns

| Smell | Fix |
|-------|-----|
| Long plan only in chat | Write `plans/NNN-*.md` now |
| File only under `~/.cursor/plans/` | Copy to repo path, then verify |
| "I'll write the plan next turn" | Handoff is same turn as plan conclusion |
| Skipping handoff because task seems small | Single-section handoff is OK; skipping is not |
| Loading writing-plans inside this skill | Keep skills independent; user composes loops |

## Quick reference

```bash
# Detect
bash scripts/detect-plan-target.sh

# Next plan number
ls plans/done/ plans/[0-9]*.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1

# Verify
git status -- plans/
```
