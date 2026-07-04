# 各 Host 的 plan 模式 → 交接落盘

本 skill 把 host plan 模式视为**草稿**。仓库文件才是**交接**。

## Cursor

| 操作 | 方式 |
|------|------|
| 进入 plan | CLI `--plan` / `--mode plan`；IDE Shift+Tab → Plan |
| 临时存储 | `~/.cursor/plans/`（UUID 文件名） |
| 交接目标 | 项目内 `plans/NNN-<主题>.md`（或检测出的根目录） |

**Agent 规则：** 在 Plan → Agent 切换或结束会话前，必须写入交接文件。若 Cursor 同时在 `~/.cursor/plans/` 写了内容，将有价值部分合并进仓库文件，**不要**把临时文件当 canonical。

## Claude Code

| 操作 | 方式 |
|------|------|
| 进入 plan | `--permission-mode plan`；工具 EnterPlanMode |
| 配置 | `.claude/settings.json` → `"plansDirectory": "./plans"` |
| 交接目标 | 带项目编号的 `plans/NNN-<主题>.md` |

**Agent 规则：** `plansDirectory` 会路由 Claude 的 plan 文件，但交接仍须 `NNN-` 编号并归档到 `<plan_root>/done/`。以 `detect-plan-target.sh` 输出为准。

## Qoder

| 操作 | 方式 |
|------|------|
| 进入 plan | `/plan` 切换 |
| 临时存储 | 会话 / host 特有路径 |
| 交接目标 | 项目内 `plans/NNN-<主题>.md` |

**Agent 规则：** 与 Cursor 相同——仓库交接文件存在前，不要退出 plan。

## 其它 agent（Codex、OpenCode、Copilot 等）

若 host 提供只读或类 plan 模式，契约相同：

1. 在 host plan/草稿区探索（若有）
2. 进入实现模式前写入仓库交接文件
3. 不要把仅用于交接的内容留在非 git 路径
