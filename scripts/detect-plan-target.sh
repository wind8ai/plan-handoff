#!/usr/bin/env bash
# 识别当前仓库的 plan 交接落盘目标。输出 env 风格行供 agent 解析。
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

PLAN_ROOT=""
SOURCE=""
NEEDS_BOOTSTRAP=0

if [[ -f .plan-handoff.yaml ]]; then
  pr="$(python3 -c "
import pathlib
try:
    import yaml
except ImportError:
    yaml = None
p = pathlib.Path('.plan-handoff.yaml')
text = p.read_text(encoding='utf-8')
if yaml:
    data = yaml.safe_load(text) or {}
    print(str(data.get('plan_root', '') or '').strip())
else:
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('plan_root:'):
            print(line.split(':', 1)[1].strip().strip('\"').strip(\"'\"))
            break
" 2>/dev/null || true)"
  if [[ -n "$pr" ]]; then
    PLAN_ROOT="$pr"
    SOURCE=".plan-handoff.yaml"
  fi
fi

if [[ -z "$PLAN_ROOT" && -f .claude/settings.json ]]; then
  pd="$(python3 -c "
import json, pathlib
p = pathlib.Path('.claude/settings.json')
d = json.loads(p.read_text()).get('plansDirectory','').strip()
print(d.lstrip('./'))
" 2>/dev/null || true)"
  if [[ -n "$pd" ]]; then
    PLAN_ROOT="$pd"
    SOURCE=".claude/settings.json"
  fi
fi

if [[ -z "$PLAN_ROOT" ]]; then
  for candidate in plans; do
    if compgen -G "${candidate}/[0-9]*.md" >/dev/null 2>&1 \
      || compgen -G "${candidate}/done/[0-9]*.md" >/dev/null 2>&1 \
      || [[ -d "${candidate}/done" ]]; then
      PLAN_ROOT="$candidate"
      SOURCE="existing ${candidate}/"
      break
    fi
  done
fi

if [[ -z "$PLAN_ROOT" ]]; then
  NEEDS_BOOTSTRAP=1
  PLAN_ROOT="plans"
  SOURCE="bootstrap-default"
fi

NEXT_NUM="001"
if [[ -d "$PLAN_ROOT" ]]; then
  last="$(ls "$PLAN_ROOT"/done/ "$PLAN_ROOT"/[0-9]*.md 2>/dev/null | grep -oE '[0-9]{3}' | sort -n | tail -1 || true)"
  if [[ -n "$last" ]]; then
    NEXT_NUM="$(printf '%03d' $((10#$last + 1)))"
  fi
fi

echo "PLAN_ROOT=$PLAN_ROOT"
echo "PLAN_SOURCE=$SOURCE"
echo "NEXT_PLAN_NUM=$NEXT_NUM"
echo "NEEDS_BOOTSTRAP=$NEEDS_BOOTSTRAP"
echo "HANDOFF_PATTERN=${PLAN_ROOT}/NNN-<kebab-topic>.md"
echo "DONE_DIR=${PLAN_ROOT}/done"
