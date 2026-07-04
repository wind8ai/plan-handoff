# Host plan mode → handoff

This skill treats host plan mode as **scratch**. The repo file is **handoff**.

## Cursor

| Action | How |
|--------|-----|
| Enter plan | CLI `--plan` / `--mode plan`; IDE Shift+Tab → Plan |
| Temp storage | `~/.cursor/plans/` (UUID filenames) |
| Handoff target | Project `plans/NNN-<topic>.md` (or detected root) |

**Agent rule:** Before switching Plan → Agent or ending session, write handoff file. If Cursor also wrote under `~/.cursor/plans/`, merge useful content into the repo file and do not treat the temp file as canonical.

## Claude Code

| Action | How |
|--------|-----|
| Enter plan | `--permission-mode plan`; tool EnterPlanMode |
| Config | `.claude/settings.json` → `"plansDirectory": "./plans"` |
| Handoff target | `plans/NNN-<topic>.md` with project numbering |

**Agent rule:** `plansDirectory` routes Claude's plan files, but projects often require `NNN-` numbering and `plans/done/` archive. Prefer project convention from `AGENTS.md` over generic random names.

## Qoder

| Action | How |
|--------|-----|
| Enter plan | `/plan` toggle |
| Temp storage | Session / host-specific |
| Handoff target | Project `plans/NNN-<topic>.md` |

**Agent rule:** Same as Cursor — exit plan only after repo handoff exists.

## Other agents (Codex, OpenCode, Copilot, …)

If the host exposes a read-only or plan-like mode, same contract:

1. Explore in host plan/scratch if available
2. Write repo handoff file before implement mode
3. Never leave handoff-only content in non-git paths
