# plan-handoff

Agent Skill：把 coding agent plan 模式输出落盘为 git 可追踪的仓库 Markdown。

支持 **Qoder、Codex、Cursor、Claude Code 等**具备 plan 模式的 coding agent。

完整说明见 **[SKILL.md](SKILL.md)**。

## 安装

```bash
# Qoder、Cursor 等
ln -sfn <本仓库路径> .agents/skills/plan-handoff

# Codex
ln -sfn <本仓库路径> .codex/skills/plan-handoff

# Claude Code
ln -sfn <本仓库路径> .claude/skills/plan-handoff
```

## 结构

```
plan-handoff/
├── SKILL.md
├── references/
└── scripts/
    ├── detect-plan-target.sh
    └── validate-plan.sh
```
