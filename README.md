# plan-handoff

轻量 agent skill：**把 coding agent 在 plan 模式下的输出，从会话内存强制落盘到 git 可追踪文件**。

Plan 模式是草稿区。Handoff（交接）是给下一个会话、agent 或人类的契约。

## 职责边界

| 负责 | 不负责 |
|------|--------|
| 识别 / 初始化 `plans/`（或项目自定义 plan 根目录） | 撰写高质量实现 plan |
| 代理 Cursor / Claude Code / Qoder plan 模式 → 仓库文件 | 拆 task、review lens、TDD |
| 最小交接模板 | 依赖 `writing-plans`、`grilling` 等 |

可与 [loop-engineering](https://github.com/wind8ai/loop-engineering-startup) 中的 skill 组合成 loop——**无相互 import**。

## 安装

**单仓库（软链或复制）：**

```bash
# Cursor / 跨 agent
mkdir -p .agents/skills
ln -sfn /path/to/plan-handoff .agents/skills/plan-handoff

# Claude Code
mkdir -p .claude/skills
ln -sfn /path/to/plan-handoff .claude/skills/plan-handoff
```

**通过 loop-engineering mono repo：**

```bash
./scripts/link-skills.sh --target /path/to/project --skills plan-handoff --claude
```

## 触发词

写计划 · 开 plan · plan 一下 · 规划 · 落 plan · plan handoff · 交接 plan

## 目录结构

```
plan-handoff/
├── SKILL.md
├── references/
│   ├── hosts.md
│   └── config-markers.md
└── scripts/
    └── detect-plan-target.sh
```

## 许可

许可文件由仓库维护者自行添加。
