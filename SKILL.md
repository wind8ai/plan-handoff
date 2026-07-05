---
name: plan-handoff
description: >-
  将 coding agent 在 plan 模式下的结论从会话内存强制落盘到仓库内 git 可追踪 Markdown。
  适用于 Qoder、Codex、Cursor、Claude Code 等的 plan 交接落盘。
  触发：写计划、开 plan、plan 一下、规划、落 plan、plan handoff、交接 plan；
  或 plan 仅留在 host 临时目录（~/.cursor/plans/、会话草稿）时。
  不负责撰写完整实现 plan，只负责落盘与带验证 Checklist 的交接模板。
compatibility: 需 bash、git。支持 Qoder、Codex、Cursor、Claude Code 等具备 plan 模式的 coding agent。
metadata:
  version: "0.0.1"
---

# Plan Handoff

会话里的 plan → 仓库文件。Plan 模式是草稿；仓库 Markdown 是交接契约。

## 何时使用

- 用户触发词（见 frontmatter `description`）
- 正在或即将进入 host plan 模式，输出会留在会话或 host 临时目录
- 用户要求 plan「可交接」「下个 agent 能接手」
- plan 探索已结束，尚未写入仓库文件

**不要用于：** 直接执行 `status: approved` 的 plan（`draft` 须先拍板）；无需 plan 的 trivial 改动。

## 硬约束

1. **仓库文件是唯一真相**——host 临时目录只是草稿。
2. **禁止**结论只留在 chat 或 git 树外路径（如 `~/.cursor/plans/`、`~/.claude/plans/`）。
3. **必须**在切回实现模式或结束前写入 plan 根目录下的文件。
4. 用了 plan 模式探索，**必须**同轮落盘——不要让用户从 chat 复制。

## 流程

### 1. 识别落盘目标

```bash
bash scripts/detect-plan-target.sh
```

解析 `PLAN_ROOT`、`NEXT_PLAN_NUM`、`NEEDS_BOOTSTRAP`、`HANDOFF_PATTERN`。不要手写重复检测逻辑。

检测优先级：`.plan-handoff.yaml`（可选）→ 已有 `plans/[0-9]*.md` → bootstrap 默认 `plans/`。

`.plan-handoff.yaml` 为**可选项**，不写时使用默认值 `plan_root: plans`。仅在需要非默认路径时创建：

```yaml
plan_root: <目录>   # 默认 plans
```

Claude Code 的 `plansDirectory` 请手动与 `plan_root` 对齐；脚本不读取该字段。

文件名：`<plan_root>/NNN-<kebab-主题>.md`。

### 2. 初始化（`NEEDS_BOOTSTRAP=1` 时）

```bash
mkdir -p <PLAN_ROOT>
```

可选写入 `.plan-handoff.yaml`（非默认路径时）；默认 `plan_root: plans` 可省略该文件。

### 3. Host plan 模式（可选）

各 host 差异见 [references/hosts.md](references/hosts.md)。

### 4. 交接写入（必须）

模板、生命周期、Verification 要求见 [references/plan-template.md](references/plan-template.md)。

- `draft`：背景 / 决策 / 任务骨架可先落盘
- `approved`：每 Task 须有 Verification 表 + Plan 级 Checklist；待决问题已清
- `done`：执行与验证全部通过后更新

**执行 agent：** 只接手 `approved`；按 Task → Steps → Verification 执行；失败则停止报告。

**Checker agent：** 只读验证；输入 plan 路径 + Task 范围；输出验证报告。

### 5. 验证交接

```bash
test -f <PLAN_ROOT>/<NNN>-<主题>.md   # 使用检测脚本给出的确切路径
git status -- <PLAN_ROOT>/
```

确认：文件在 git 可追踪路径；含 `status` frontmatter；关键内容不在 host 临时目录独有；`approved` 时 Verification 与 Plan 级 Checklist 齐全且无模糊项。

告知用户：交接路径、plan 编号、当前 status、是否委派 checker agent。

## 反模式

| 气味 | 修正 |
|------|------|
| plan 只在 chat / host 临时目录 | 立即写 `<PLAN_ROOT>/<NNN>-<主题>.md` |
| 「下轮再写 plan」 | 同轮 handoff |
| `draft` 直接开干 | 先拍板为 `approved` |
| `approved` 无 Verification 表 | 补全再拍板 |
| Verification 写「跑测试」 | 改为确切命令 + 期望输出 |
| 执行 agent 自验自批 | 关键项委派 checker agent |
| Checker 边验边改代码 | Checker 只读；修复交回执行 agent |
| 完成 plan 后搬到 `done/` 目录 | 改 `status: done` |

## 速查

```bash
bash scripts/detect-plan-target.sh
git status -- <PLAN_ROOT>/
```
