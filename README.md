# plan-handoff

轻量 agent skill：**把 coding agent 在 plan 模式下的输出，从会话内存强制落盘到 git 可追踪文件**。

Plan 模式是草稿区。Handoff（交接）是给下一个会话、agent 或人类的契约。

## 职责边界

| 负责 | 不负责 |
|------|--------|
| 识别 / 初始化 `plans/`（或 `.plan-handoff.yaml` 自定义根目录） | 撰写完整实现 plan |
| 代理 Qoder / Codex / Cursor / Claude Code plan 模式 → 仓库文件 | 拆 task、review、TDD |
| 交接模板（Task + Verification Checklist + checker 委派） | — |

## 安装

**单仓库（软链或复制）：**

```bash
# 跨 agent（Cursor 等）
mkdir -p .agents/skills
ln -sfn /path/to/plan-handoff .agents/skills/plan-handoff

# Claude Code
mkdir -p .claude/skills
ln -sfn /path/to/plan-handoff .claude/skills/plan-handoff
```

## 触发词

写计划 · 开 plan · plan 一下 · 规划 · 落 plan · plan handoff · 交接 plan

## 目录结构

```
plan-handoff/
├── SKILL.md
└── scripts/
    └── detect-plan-target.sh
```

## 配置

唯一配置源：`.plan-handoff.yaml`（可选）

```yaml
plan_root: plans
```

Plan 生命周期用 frontmatter `status: draft | approved | done` 管理。`approved` 要求每个 Task 带 Verification 检查表 + Plan 级 Checklist，可委派独立 checker agent 验收。

## 许可

许可文件由仓库维护者自行添加。
