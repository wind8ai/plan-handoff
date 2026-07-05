---
name: plan-handoff
description: >-
  将 coding agent 在 plan 模式下的结论从会话内存强制落盘到仓库内 git 可追踪文件。
  自动识别或初始化 plan 目录（.plan-handoff.yaml、plans/）。
  触发：写计划、开 plan、plan 一下、规划、落 plan、plan handoff、交接 plan；
  或 plan 仅留在 host 临时目录（~/.cursor/plans/、会话草稿）时。
  不负责写 plan、拆 task——可与 writing-plans、grilling、planning-and-task-breakdown 组合，无相互依赖。
version: 0.3.0
---

# Plan Handoff — Plan 交接落盘

**只做一件事：** 会话里的 plan → 仓库文件。没有别的。

Plan 模式用来想。**Handoff（交接）** 用来持久化——让下一个会话、另一个 agent 或人类接手时，不必重新推导上下文。

本 skill **不**决定 plan 质量、不拆 task、不做 review。那些交给其它 skill。本 skill 只保证 plan **落在磁盘上的正确位置**。

深度 task 拆解或 ExecPlan 级规格，后续用 `writing-plans` 或项目 `PLANS.md` 扩写——本 skill 只产出**最小交接文档**。

## 何时使用

**以下任一成立即加载：**

- 用户触发词：写计划 / 写 plan / 开 plan / plan 一下 / 规划一下 / 落 plan / plan handoff / 交接 plan
- 你正在（或即将进入）host plan 模式，且输出会留在会话或 host 临时目录
- 用户要求 plan「可交接」「下个 agent 能接手」
- plan 模式探索已结束，但尚未写入仓库文件

**不要使用于：**

- 执行已有 plan（直接 Read `plans/NNN-*.md` 并实现）
- 无 plan 模式阶段、从零写完整实现 plan（用 `writing-plans` 或项目 SDD skill）
- 单行 typo 等无需 plan 文件的改动

## 硬约束

1. **仓库文件是唯一真相。** Host 临时 plan 目录只是草稿。
2. **禁止**在 plan 会话结束时，结论只留在 chat 或 host 临时路径：
   - `~/.cursor/plans/`
   - `~/.claude/plans/`（随机文件名）
   - 项目 git 树外的任何路径
3. **必须**在切回 agent/实现模式或结束前，在识别出的 plan 根目录下写入（或更新）文件。
4. **禁止** import 或依赖其它 skill。仅可选组合（例如 handoff 前加载 `grilling`，之后加载 `writing-plans`——由用户决定）。
5. 若用了 plan 模式做探索，**必须**把结论写入仓库文件——不要让用户从 chat 复制粘贴。

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
| Cursor | `--plan`、`--mode plan`、Shift+Tab Plan | `~/.cursor/plans/`（UUID 文件名） |
| Claude Code | `--permission-mode plan`、EnterPlanMode | 经 `plansDirectory` 路由——仍须 `NNN-*.md` 命名 |
| Qoder | `/plan` 切换 | 会话 / host 临时 |
| Copilot / 其它 | host 类 plan / 只读探索模式 | host 默认路径（如 `.copilot/plans/`） |

**Agent 规则：** 在 Plan → Agent 切换或结束会话前，必须写入交接文件。若 host 同时在临时目录写了内容，将有价值部分合并进仓库文件，**不要**把临时文件当 canonical。

### 步骤 4 — 交接写入（必须）

写入或更新目标文件。最小可交接模板：

```markdown
---
status: draft
handoff: 2026-07-05
host: Cursor
---

# Plan NNN — <主题>

## 背景
<为何需要此 plan——零上下文读者也能看懂>

## 决策
<plan 模式中已拍板的内容—— bullet 列表>

## 待决问题
<未决事项，或写「无」>

## 下一步
<执行者应做的第一件事——至少一行>
```

**生命周期：** 用 frontmatter `status` 管理，**不要**搬移文件：

| status | 含义 |
|--------|------|
| `draft` | 进行中，可继续编辑 |
| `done` | 已完成，保留原位供 git 历史追踪 |

完成时把 `status: draft` 改为 `status: done` 即可。若仓库已有 `plans/done/` 旧结构，可保留但不新建。

**内容策略：** 从 plan 模式整理粘贴即可。深度 task 拆解**可选**——若用户需要，后续再用 `writing-plans` / `planning-and-task-breakdown`。

**更新已有 plan：** 编辑同一 `plans/NNN-*.md`；更新 frontmatter `handoff` 日期或追加简短变更记录。

### 步骤 5 — 验证交接

离开 plan 模式或结束本轮前：

```bash
test -f plans/NNN-*.md   # 使用检测脚本给出的确切路径
git status -- plans/
```

确认：

- [ ] 文件存在于 git 可追踪的 plan 根目录下
- [ ] 关键内容不在 chat 或 `~/.cursor/plans/` 中独有
- [ ] 含 `status` frontmatter
- [ ] 文内路径为仓库相对路径（无 `/Users/...`）

告知用户：**交接路径**、**plan 编号**、以及现在 commit 还是继续编辑。

## 组合使用（可选，非必须）

| 阶段 | 示例 skill | 作用 |
|------|------------|------|
| plan 模式前 | `grilling`、`brainstorming` | 对齐范围 |
| plan 模式 | *（host 原生）* | 探索 |
| **交接落盘** | **`plan-handoff`** | **写入仓库** |
| handoff 后 | `writing-plans`、`planning-and-task-breakdown` | 扩写 task / 提升质量 |
| 执行 | `executing-plans`、项目 loop | 实现 |

## 反模式

| 气味 | 修正 |
|------|------|
| 长 plan 只在 chat 里 | 立即写 `plans/NNN-*.md` |
| 文件只在 `~/.cursor/plans/` | 合并到仓库路径并验证 |
| 「下轮再写 plan」 | handoff 与 plan 结论同轮完成 |
| 任务小就跳过 handoff | 单段 handoff 可以；跳过不行 |
| 在本 skill 内加载 writing-plans | skill 保持独立；由用户组 loop |
| 完成 plan 后搬到 `done/` 目录 | 改 frontmatter `status: done` |

## 速查

```bash
bash scripts/detect-plan-target.sh
git status -- plans/
```
