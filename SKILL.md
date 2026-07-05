---
name: plan-handoff
description: >-
  将 coding agent 在 plan 模式下的结论从会话内存强制落盘到仓库内 git 可追踪文件。
  自动识别或初始化 plan 目录（.plan-handoff.yaml、plans/）。
  触发：写计划、开 plan、plan 一下、规划、落 plan、plan handoff、交接 plan；
  或 plan 仅留在 host 临时目录（~/.cursor/plans/、会话草稿）时。
  不负责撰写完整实现 plan 或拆 task，只负责交接落盘与验证模板。
version: 0.0.1
---

# Plan Handoff — Plan 交接落盘

**只做一件事：** 会话里的 plan → 仓库文件。没有别的。

Plan 模式用来想。**Handoff（交接）** 用来持久化——让下一个会话、另一个 agent 或人类接手时，不必重新推导上下文。

本 skill 只保证 plan **落在磁盘上的正确位置**，并提供**带验证 Checklist 的交接模板**，确保 `approved` 状态可交付执行 agent 与独立 checker agent。

## 何时使用

**以下任一成立即加载：**

- 用户触发词：写计划 / 写 plan / 开 plan / plan 一下 / 规划一下 / 落 plan / plan handoff / 交接 plan
- 你正在（或即将进入）host plan 模式，且输出会留在会话或 host 临时目录
- 用户要求 plan「可交接」「下个 agent 能接手」
- plan 模式探索已结束，但尚未写入仓库文件

**不要使用于：**

- 执行已有 plan（查找 `status: approved` 的 `plans/NNN-*.md` 并实现；`draft` 须先拍板）
- 无 plan 探索阶段、仅需直接改代码的场景
- 单行 typo 等无需 plan 文件的改动

## 硬约束

1. **仓库文件是唯一真相。** Host 临时 plan 目录只是草稿。
2. **禁止**在 plan 会话结束时，结论只留在 chat 或 host 临时路径：
   - `~/.cursor/plans/`
   - `~/.claude/plans/`（随机文件名）
   - 项目 git 树外的任何路径
3. **必须**在切回 agent/实现模式或结束前，在识别出的 plan 根目录下写入（或更新）文件。
4. 若用了 plan 模式做探索，**必须**把结论写入仓库文件——不要让用户从 chat 复制粘贴。

## 流程

### 步骤 1 — 识别 plan 落盘目标

运行检测脚本，解析其输出（不要手写重复逻辑）：

```bash
bash scripts/detect-plan-target.sh
```

输出字段：

| 字段 | 含义 |
|------|------|
| `PLAN_ROOT` | plan 根目录 |
| `PLAN_SOURCE` | 检测依据 |
| `NEXT_PLAN_NUM` | 下一个三位编号 |
| `NEEDS_BOOTSTRAP` | `1` 表示需初始化 |
| `HANDOFF_PATTERN` | 文件名模式 |

**检测优先级：**

| 优先级 | 标记 | Plan 根目录 |
|--------|------|-------------|
| 1 | `.plan-handoff.yaml` → `plan_root` | 配置值（默认 `plans`） |
| 2 | 已有 `plans/[0-9]*.md` | `plans/` |
| 3 | 无任何标记 | **初始化**（步骤 2）后使用 `plans/` |

**配置（唯一配置源）：** 仅在需要非默认路径时创建 `.plan-handoff.yaml`：

```yaml
plan_root: plans
```

示例自定义根目录：

```yaml
plan_root: docs/plans
```

**Claude Code 用户：** 若使用 `.claude/settings.json` 的 `plansDirectory`，请手动与 `plan_root` 对齐（例如 `"plansDirectory": "./plans"`）。检测脚本**不**读取该字段。

**文件名约定：** `<plan_root>/NNN-<kebab-主题>.md`（三位递增编号，由脚本给出 `NEXT_PLAN_NUM`）。

### 步骤 2 — 初始化（仅当 `NEEDS_BOOTSTRAP=1`）

```bash
mkdir -p plans
```

可选写入 `.plan-handoff.yaml`（非默认路径时推荐）：

```yaml
plan_root: plans
```

重新运行 `detect-plan-target.sh`，确认 `PLAN_ROOT=plans`。

### 步骤 3 — Host plan 模式（可选草稿区）

需要探索时，可使用 host 原生 plan 模式。Host 差异见下表；**规则相同**：host 临时区是草稿，仓库文件是交接。

| Host | 进入 plan | 临时存储（仅草稿） |
|------|-----------|-------------------|
| Qoder | `/plan` 切换 | 会话 / host 临时 |
| Codex | plan 模式（CLI / App） | 会话 / host 临时 |
| Cursor | `--plan`、`--mode plan`、Shift+Tab Plan | `~/.cursor/plans/`（UUID 文件名） |
| Claude Code | `--permission-mode plan`、EnterPlanMode | 经 `plansDirectory` 路由——仍须 `NNN-*.md` 命名 |

**Agent 规则：** 在 Plan → Agent 切换或结束会话前，必须写入交接文件。若 host 同时在临时目录写了内容，将有价值部分合并进仓库文件，**不要**把临时文件当 canonical。

### 步骤 4 — 交接写入（必须）

写入或更新目标文件。模板分两层：`draft` 可只填前半；标 `approved` 前必须补全 **任务 + 验证 Checklist**。

```markdown
---
status: draft
handoff: 2026-07-05
host: Qoder
goal: <一句话目标>
---

# Plan NNN — <主题>

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

每个 Task 须 **适度颗粒度**：一个可独立验收的交付单元，自带完成检查，而非笼统步骤。

### Task 1: <组件或交付单元名>

**Files:**
- Create: `path/to/new.ts`
- Modify: `path/to/existing.ts`
- Test: `path/to/test.ts`

**Steps:**
- [ ] Step 1: <具体动作>
- [ ] Step 2: <具体动作>

**Verification（Task 完成检查 — 必填）:**

| # | 检查项 | 命令 / 动作 | 期望结果 | 执行者 |
|---|--------|-------------|----------|--------|
| 1 | 单元测试 | `npm test -- path/to/test.ts` | PASS | 执行 agent |
| 2 | 类型检查 | `tsc --noEmit` | 无错误 | 执行 agent |
| 3 | 行为验收 | <具体手动步骤> | <可观察结果> | checker agent |

> Verification 禁止写「跑一下测试」「确保没问题」等模糊项——须给出**确切命令或动作 + 期望输出**。

### Task 2: <下一交付单元>
...

## 验证 Checklist（Plan 级 — `approved` 必填）

全部 Task 完成后、改 `status: done` 之前执行：

- [ ] 每个 Task 的 Verification 表已全部通过
- [ ] 端到端 / 集成验证：`<命令>` → 期望：`<结果>`
- [ ] 对照 **不做** 清单，确认无 scope creep
- [ ] 关键路径已 commit，工作区干净（或符合项目约定）

## 验证委派（Checker Agent — 可选）

当验证需要**独立于执行 agent** 时（maker-checker），按此契约委派：

| 字段 | 约定 |
|------|------|
| 触发时机 | 每个 Task 完成后 / 全部 Task 完成后 |
| Checker 输入 | 本 plan 文件路径 + Task 编号（或 `all`） |
| Checker 职责 | **只读验证**：逐项执行 Verification 表与 Plan 级 Checklist，勾选结果；**不改代码** |
| Checker 输出 | 验证报告：通过项 / 失败项 / 阻塞项 |
| 失败处理 | 退回执行 agent 修复；严重偏差则 `approved` → `draft` 并更新 plan |

Checker 可以是新会话 agent、子 agent、或独立验证 agent——由用户配置。

## 下一步
<执行 agent 第一件事；通常为 Task 1 Step 1>
```

**格式要点：**

| 要素 | 要求 |
|------|------|
| Task 粒度 | 一个 Task = 一个可独立验收的交付单元（含 Files + Steps + Verification） |
| Steps | 用 `- [ ]` checkbox，执行 agent 逐项勾选 |
| Verification | **每个 Task 必填**验证表；禁止 TBD /「后续补」 |
| Plan 级 Checklist | `approved` 前必须有；表达跨 Task 的整体验收 |
| Checker 委派 | 验证表「执行者」列标明 `执行 agent` 或 `checker agent` |

**生命周期：** 用 frontmatter `status` 管理，**不要**搬移文件：

| status | 含义 | 模板要求 |
|--------|------|----------|
| `draft` | 规划中，可继续编辑 | 背景 / 决策 / 待决可先行；任务与验证可骨架化 |
| `approved` | **已拍板，可交付执行** | **每个 Task 须有 Verification 表；须有 Plan 级 Checklist** |
| `done` | 执行与验证已完成 | Plan 级 Checklist 全部勾选；Verification 已通过 |

状态流转：

```
draft → approved → done
  ↑         │
  └─────────┘  （验证失败或方案变更，退回 draft）
```

**何时标 `approved`：** 待决问题为「无」或已解决；每个 Task 的 Verification 已写全（无 TBD）；用户确认可开始实现。

**执行 agent 契约：** 只接手 `status: approved` 的 plan；按 Task → Steps → Verification 顺序执行；Verification 失败时停止并报告，不猜测。

**Checker agent 契约：** 只读；输入为 plan 路径 + Task 范围；输出验证报告；不修改代码或 plan（除非用户要求退回 `draft`）。

执行与验证全部通过后，把 `status: approved` 改为 `status: done`。

**内容策略：**

- plan 模式 handoff：先落盘 `draft`，填入背景 / 决策 / 任务骨架
- 标 `approved` 前：补全 Task Steps 与 Verification，确保无模糊项、Plan 级 Checklist 已就绪

**更新已有 plan：** 编辑同一 `plans/NNN-*.md`；更新 frontmatter `handoff` 日期；执行中勾选 Steps / Checklist checkbox。

### 步骤 5 — 验证交接

离开 plan 模式或结束本轮前：

```bash
test -f plans/NNN-*.md   # 使用检测脚本给出的确切路径
git status -- plans/
```

确认：

- [ ] 文件存在于 git 可追踪的 plan 根目录下
- [ ] 关键内容不在 chat 或 host 临时目录中独有
- [ ] 含 `status` frontmatter
- [ ] 文内路径为仓库相对路径（无 `/Users/...`）
- [ ] 若 `status: approved`：每个 Task 有 Verification 表，且有 Plan 级 Checklist
- [ ] Verification 无 TBD / 模糊项（须含确切命令或动作 + 期望结果）

告知用户：**交接路径**、**plan 编号**、**当前 status**（`draft` 可继续改，`approved` 可交给执行 agent），以及验证是否委派 checker agent。

## 工作流

| 阶段 | 动作 |
|------|------|
| 探索 | host plan 模式（Qoder / Codex / Cursor / Claude Code） |
| 落盘 | 写入 `plans/NNN-*.md`，`status: draft` |
| 拍板 | 补全 Verification + Plan 级 Checklist → `status: approved` |
| 执行 | 执行 agent 按 Task 完成 Steps 与 Verification |
| 验证 | checker agent 独立验收（可选） |
| 归档 | 全部通过后 `status: done` |

## 反模式

| 气味 | 修正 |
|------|------|
| 长 plan 只在 chat 里 | 立即写 `plans/NNN-*.md` |
| 文件只在 host 临时目录 | 合并到仓库路径并验证 |
| 「下轮再写 plan」 | handoff 与 plan 结论同轮完成 |
| 任务小就跳过 handoff | 单段 handoff 可以；跳过不行 |
| 完成 plan 后搬到 `done/` 目录 | 改 frontmatter `status: done` |
| 对 `draft` plan 直接开干 | 先拍板为 `approved`，或回到 plan 模式补全 |
| handoff 时标 `approved` 但待决问题未清 | 保持 `draft`，列出待决项 |
| `approved` 但 Task 无 Verification 表 | 补全验证项再拍板 |
| Verification 写「跑测试」「检查一下」 | 改为确切命令 + 期望输出 |
| 执行 agent 自验自批 | 关键项委派 checker agent（maker-checker） |
| Checker agent 边验边改代码 | Checker 只读；修复交回执行 agent |

## 速查

```bash
bash scripts/detect-plan-target.sh
git status -- plans/
```
