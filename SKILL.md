---
name: plan-handoff
description: >-
  将 coding agent 在 plan 模式下的结论从会话内存强制落盘到仓库内 git 可追踪文件。
  自动识别或初始化 plan 目录配置（AGENTS.md、plans/、Claude plansDirectory）。
  触发：写计划、开 plan、plan 一下、规划、落 plan、plan handoff、交接 plan；
  或 plan 仅留在 host 临时目录（~/.cursor/plans/、会话草稿）时。
  不负责写 plan、拆 task——可与 writing-plans、grilling、planning-and-task-breakdown 组合，无相互依赖。
version: 0.1.0
---

# Plan Handoff — Plan 交接落盘

**只做一件事：** 会话里的 plan → 仓库文件。没有别的。

Plan 模式用来想。**Handoff（交接）** 用来持久化——让下一个会话、另一个 agent 或人类接手时，不必重新推导上下文。

本 skill **不**决定 plan 质量、不拆 task、不做 review。那些交给其它 skill。本 skill 只保证 plan **落在磁盘上的正确位置**。

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

运行检测（或手动读标记）：

```bash
bash scripts/detect-plan-target.sh
```

按优先级读取，直到确定 plan 根目录：

| 优先级 | 标记 | Plan 根目录 |
|--------|------|-------------|
| 1 | `AGENTS.md` — Plan 相关节 / §3.0 /「开计划」/`plans/NNN` | AGENTS 中指定的路径（默认 `plans/`） |
| 2 | `plans/README.md` | `plans/` |
| 3 | `.claude/settings.json` → `plansDirectory` | 相对仓库根的路径 |
| 4 | 已有 `plans/[0-9]*.md` 或 `plans/done/` | `plans/` |
| 5 | 无任何标记 | **初始化**（步骤 2）后使用 `plans/` |

grep 模式见 [references/config-markers.md](references/config-markers.md)。

**文件名约定**（除非 AGENTS 另有规定）：

- 进行中：`plans/NNN-<kebab-主题>.md`（三位递增编号）
- 已完成：`plans/done/NNN-<kebab-主题>.md`

取下一个编号：

```bash
ls plans/done/ plans/[0-9]*.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1
# 末号 +1，补零至 3 位；若无则从 001 起
```

### 步骤 2 — 初始化（仅当步骤 1 未发现配置）

创建最小目录结构——**不要**发明项目专属的 plan 方法论：

```
plans/
├── README.md    # 说明：plan 文件在此；完整规范见 AGENTS.md（若后续补充）
└── done/
```

若本仓使用 Claude Code，在 `.claude/settings.json` 中新增或合并：

```json
{
  "plansDirectory": "./plans"
}
```

可选：在 `AGENTS.md` 末尾追加简短「Plan 交接」_stub（3–5 行：触发词 + `plans/NNN-*.md` + 归档到 `plans/done/`）。**不要**重写已有 AGENTS 内容。

重新运行 `detect-plan-target.sh`，确认 `PLAN_ROOT=plans`。

### 步骤 3 — Host plan 模式（可选草稿区）

需要探索时，可使用 host 原生 plan 模式。详见 [references/hosts.md](references/hosts.md)。

| Host | 进入 plan | 临时存储（仅草稿） |
|------|-----------|-------------------|
| Cursor | `--plan`、`--mode plan`、Shift+Tab Plan | `~/.cursor/plans/` |
| Claude Code | `--permission-mode plan`、EnterPlanMode | 经 `plansDirectory` 路由——仍须 `NNN-*.md` 命名 |
| Qoder | `/plan` 切换 | 会话 / host 临时 |

**在 plan 模式中：** 自由记录。**退出前：** 所有影响交接的决策必须进入仓库文件。

### 步骤 4 — 交接写入（必须）

写入或更新目标文件。最小可交接模板：

```markdown
# Plan NNN — <主题>

> Status: 📋 Draft
> Handoff: <ISO 日期> via plan-handoff
> Host: Cursor | Claude Code | Qoder | 其他

## 背景
<为何需要此 plan——零上下文读者也能看懂>

## 决策
<plan 模式中已拍板的内容—— bullet 列表>

## 待决问题
<未决事项，或写「无」>

## 下一步
<执行者应做的第一件事——至少一行>
```

**内容策略：** 从 plan 模式整理粘贴即可。深度 task 拆解**可选**——若用户需要，后续再用 `writing-plans` / `planning-and-task-breakdown`。

**更新已有 plan：** 编辑同一 `plans/NNN-*.md`；在背景段追加 `> Handoff:` 行或简短变更记录。

### 步骤 5 — 验证交接

离开 plan 模式或结束本轮前：

```bash
test -f plans/NNN-*.md   # 或检测脚本给出的确切路径
git status -- plans/
```

确认：

- [ ] 文件存在于 git 可追踪的 plan 根目录下
- [ ] 关键内容不在 chat 或 `~/.cursor/plans/` 中独有
- [ ] 含 Status 行
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

## 速查

```bash
# 识别
bash scripts/detect-plan-target.sh

# 下一个 plan 编号
ls plans/done/ plans/[0-9]*.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1

# 验证
git status -- plans/
```
