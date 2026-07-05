#!/usr/bin/env bash
# 识别当前仓库的 plan 交接落盘目标。输出 env 风格行供 agent 解析。
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

PLAN_ROOT=""
SOURCE=""
NEEDS_BOOTSTRAP=0

read_plan_root_from_yaml() {
  local file=".plan-handoff.yaml"
  [[ -f "$file" ]] || return 1
  local line value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" =~ ^plan_root:[[:space:]]*(.+)$ ]]; then
      value="${BASH_REMATCH[1]}"
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      value="${value%"${value##*[![:space:]]}"}"
      value="${value#"${value%%[![:space:]]*}"}"
      [[ -n "$value" ]] && { printf '%s' "$value"; return 0; }
    fi
  done < "$file"
  return 1
}

has_numbered_plans() {
  local dir="$1"
  local f
  [[ -d "$dir" ]] || return 1
  shopt -s nullglob
  for f in "$dir"/[0-9]*.md; do
    shopt -u nullglob
    return 0
  done
  shopt -u nullglob
  return 1
}

if pr="$(read_plan_root_from_yaml)"; then
  PLAN_ROOT="$pr"
  SOURCE=".plan-handoff.yaml"
fi

if [[ -z "$PLAN_ROOT" ]] && has_numbered_plans "plans"; then
  PLAN_ROOT="plans"
  SOURCE="existing plans/"
fi

if [[ -z "$PLAN_ROOT" ]]; then
  NEEDS_BOOTSTRAP=1
  PLAN_ROOT="plans"
  SOURCE="bootstrap-default"
fi

NEXT_NUM="001"
if [[ -d "$PLAN_ROOT" ]]; then
  last="$(
    {
      shopt -s nullglob
      for f in "$PLAN_ROOT"/[0-9]*.md; do
        basename "$f"
      done
      shopt -u nullglob
    } | grep -oE '^[0-9]{3}' | sort -n | tail -1 || true
  )"
  if [[ -n "$last" ]]; then
    NEXT_NUM="$(printf '%03d' $((10#$last + 1)))"
  fi
fi

echo "PLAN_ROOT=$PLAN_ROOT"
echo "PLAN_SOURCE=$SOURCE"
echo "NEXT_PLAN_NUM=$NEXT_NUM"
echo "NEEDS_BOOTSTRAP=$NEEDS_BOOTSTRAP"
echo "HANDOFF_PATTERN=${PLAN_ROOT}/NNN-<kebab-topic>.md"
