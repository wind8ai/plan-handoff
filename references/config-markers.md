# Plan 落盘目标识别标记

供 `scripts/detect-plan-target.sh` 及手动 fallback 使用。

## AGENTS.md 模式

```bash
grep -nE 'plans/NNN|开计划|写计划|Plan 协议|plan-handoff|plansDirectory' AGENTS.md 2>/dev/null
```

常见信号：

- `plans/NNN-<主题>.md` 或 `plans/NNN-*.md`
- 「开计划」/「Plan 协议」/ §3.0 等章节
- 明确禁止：以 host 临时 plan 模式作为主存储

AGENTS 提到 `plans/` 但未指定其它路径时，默认根目录为 **`plans/`**。

## plans/README.md

若存在，plan 根目录为 README 所在目录（通常为 `plans/`）。

## Claude Code

```bash
python3 -c "
import json, pathlib
p = pathlib.Path('.claude/settings.json')
print(json.loads(p.read_text()).get('plansDirectory','')) if p.exists() else print('')
"
```

相对路径以仓库根为基准。

## 已有 plan 活动

```bash
ls plans/[0-9]*.md plans/done/[0-9]*.md 2>/dev/null | head -3
```

若已有文件，即使没有 AGENTS，根目录也为 `plans/`。

## 初始化阈值

**以下全部为假**时才初始化：

- AGENTS.md 中有 plan 相关节
- `plans/README.md` 存在
- `plans/[0-9]*.md` 或 `plans/done/` 存在
- `.claude/settings.json` 含 `plansDirectory`

初始化会创建 `plans/`、`plans/done/`、最小 `plans/README.md`，并可选合并 `.claude/settings.json`。
