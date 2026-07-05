# Plan 交接模板

handoff 写入时使用。`draft` 可只填前半；标 `approved` 前须补全任务与验证 Checklist。

下列 `<…>` 为占位符，写入时替换为实际值。

```markdown
---
status: draft
handoff: <YYYY-MM-DD>
host: <Qoder|Codex|Cursor|Claude Code|…>
goal: <一句话目标>
---

# Plan <NNN> — <主题>

> **For agents:** 读取 `status: approved` 的 plan，按 Task 执行 Steps 与 Verification；可委派独立 checker agent（见 §验证委派）。

**Goal:** <与 frontmatter goal 一致>
**Architecture:** <2-3 句方案概要>
**不做:** <明确 out-of-scope，防 scope creep>

## 背景
<为何需要此 plan——零上下文读者也能看懂>

## 决策
<plan 模式中已拍板的内容—— bullet 列表>

## 待决问题
<未决事项，或写「无」>

## 任务

每个 Task 须适度颗粒度：一个可独立验收的交付单元，自带完成检查。

### Task <N>: <组件或交付单元名>

**Files:**
- Create: `<path/to/new>`
- Modify: `<path/to/existing>`
- Test: `<path/to/test>`

**Steps:**
- [ ] Step 1: <具体动作>
- [ ] Step 2: <具体动作>

**Verification（Task 完成检查 — 必填）:**

| # | 检查项 | 命令 / 动作 | 期望结果 | 执行者 |
|---|--------|-------------|----------|--------|
| 1 | <检查项名> | `<命令或动作>` | <期望结果> | 执行 agent |
| 2 | <检查项名> | `<命令或动作>` | <期望结果> | 执行 agent |
| 3 | <检查项名> | `<命令或动作>` | <期望结果> | checker agent |

> Verification 禁止模糊项——须给出确切命令或动作 + 期望输出。

### Task <N+1>: <下一交付单元>
...

## 验证 Checklist（Plan 级 — `approved` 必填）

- [ ] 每个 Task 的 Verification 表已全部通过
- [ ] 端到端 / 集成验证：`<命令>` → 期望：`<结果>`
- [ ] 对照 **不做** 清单，确认无 scope creep
- [ ] 关键路径已 commit，工作区干净（或符合项目约定）

## 验证委派（Checker Agent — 可选）

| 字段 | 约定 |
|------|------|
| 触发时机 | 每个 Task 完成后 / 全部 Task 完成后 |
| Checker 输入 | 本 plan 文件路径 + Task 编号（或 `all`） |
| Checker 职责 | 只读验证；不改代码 |
| Checker 输出 | 验证报告：通过项 / 失败项 / 阻塞项 |
| 失败处理 | 退回执行 agent；严重偏差则 `approved` → `draft` |

## 下一步
<执行 agent 第一件事；通常为 Task 1 Step 1>
```

## 格式要点

| 要素 | 要求 |
|------|------|
| Task 粒度 | 一个 Task = 可独立验收的交付单元（Files + Steps + Verification） |
| Steps | `- [ ]` checkbox |
| Verification | 每个 Task 必填；禁止 TBD |
| Plan 级 Checklist | `approved` 前必须有 |
| Checker 委派 | 「执行者」列标明执行 agent 或 checker agent |

## 生命周期

| status | 含义 | 要求 |
|--------|------|------|
| `draft` | 规划中 | 背景 / 决策可先写；任务与验证可骨架化 |
| `approved` | 已拍板，可交付执行 | 每 Task 有 Verification 表 + Plan 级 Checklist |
| `done` | 执行与验证已完成 | Checklist 全勾、Verification 已通过 |

```
draft → approved → done
  ↑         │
  └─────────┘
```
