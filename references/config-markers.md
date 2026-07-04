# Plan 落盘目标识别

供 `scripts/detect-plan-target.sh` 及手动 fallback 使用。识别依据见下表。

## 检测优先级

| 优先级 | 标记 | Plan 根目录 |
|--------|------|-------------|
| 1 | `.plan-handoff.yaml` → `plan_root` | 配置值 |
| 2 | `.claude/settings.json` → `plansDirectory` | 相对仓库根的路径 |
| 3 | 已有 `plans/[0-9]*.md` 或 `plans/done/` | `plans/` |
| 4 | 无信号 | bootstrap → `plans/`（见 SKILL 步骤 2） |

## `.plan-handoff.yaml`（可选）

仅在需要非默认路径时创建：

```yaml
plan_root: plans
```

示例自定义根目录：

```yaml
plan_root: docs/plans
```

## Claude Code

```bash
python3 -c "
import json, pathlib
p = pathlib.Path('.claude/settings.json')
print(json.loads(p.read_text()).get('plansDirectory','')) if p.exists() else print('')
"
```

`plansDirectory` 与 `.plan-handoff.yaml` 同时存在时，**以 `.plan-handoff.yaml` 为准**。

## 已有 plan 活动

```bash
ls plans/[0-9]*.md plans/done/[0-9]*.md 2>/dev/null | head -3
```

若已有编号 plan 文件，根目录即为 `plans/`（或文件所在目录）。

## Bootstrap 阈值

以下**全部为假**时才初始化：

- `.plan-handoff.yaml` 存在且含 `plan_root`
- `.claude/settings.json` 含 `plansDirectory`
- `plans/[0-9]*.md` 或 `plans/done/` 存在

初始化仅创建目录：`plans/`、`plans/done/`；可选写入默认 `.plan-handoff.yaml`。
