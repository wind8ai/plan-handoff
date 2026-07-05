# Host plan 模式

host 临时区是草稿，仓库 `<PLAN_ROOT>/<NNN>-<主题>.md` 是交接。下列为常见 host，不局限于此：

| Host | 进入 plan | 临时存储（仅草稿） |
|------|-----------|-------------------|
| Qoder | `/plan` 切换 | 会话 / host 临时 |
| Codex | plan 模式（CLI / App） | 会话 / host 临时 |
| Cursor | `--plan`、`--mode plan`、Shift+Tab Plan | `~/.cursor/plans/`（UUID 文件名） |
| Claude Code | `--permission-mode plan`、EnterPlanMode | 经 `plansDirectory` 路由——仍须 `NNN-*.md` 命名 |

Plan → Agent 切换或结束会话前，必须写入仓库交接文件。临时目录内容合并进仓库文件，**不要**把临时文件当 canonical。
