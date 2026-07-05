# plan-handoff

Agent Skill：把 coding agent plan 模式输出落盘为 git 可追踪的仓库 Markdown。

完整说明见 **[SKILL.md](SKILL.md)**。

## 安装

```bash
# 项目级（推荐路径因 host 而异）
ln -sfn /path/to/plan-handoff .agents/skills/plan-handoff   # Cursor 等
ln -sfn /path/to/plan-handoff .claude/skills/plan-handoff   # Claude Code
ln -sfn /path/to/plan-handoff .codex/skills/plan-handoff    # Codex
```

## 结构

```
plan-handoff/
├── SKILL.md
├── references/
└── scripts/detect-plan-target.sh
```
