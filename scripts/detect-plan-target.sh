#!/usr/bin/env bash
# Detect plan handoff target in current repo. Prints env-style lines for agents.
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

PLAN_ROOT=""
SOURCE=""
NEEDS_BOOTSTRAP=0

if [[ -f AGENTS.md ]]; then
  if grep -qE 'plans/NNN|plans/\[0-9\]|开计划|写计划|Plan 协议|plan-handoff' AGENTS.md 2>/dev/null; then
    PLAN_ROOT="plans"
    SOURCE="AGENTS.md"
  fi
fi

if [[ -z "$PLAN_ROOT" && -f plans/README.md ]]; then
  PLAN_ROOT="plans"
  SOURCE="plans/README.md"
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
  if compgen -G 'plans/[0-9]*.md' >/dev/null 2>&1 || compgen -G 'plans/done/[0-9]*.md' >/dev/null 2>&1; then
    PLAN_ROOT="plans"
    SOURCE="existing plans/*.md"
  fi
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
