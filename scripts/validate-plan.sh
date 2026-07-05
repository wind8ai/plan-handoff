#!/usr/bin/env bash
# 校验 plan 交接文件格式。exit 0=通过，1=失败，2=用法错误。
set -euo pipefail

usage() {
  echo "Usage: validate-plan.sh <plan-file.md>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage

FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0

err() {
  echo "error: $1" >&2
  ERRORS=$((ERRORS + 1))
}

warn() {
  echo "warning: $1" >&2
}

[[ -f "$FILE" ]] || { err "file not found: $FILE"; exit 1; }

BASENAME="$(basename "$FILE")"
if [[ ! "$BASENAME" =~ ^[0-9]{3}-.+\.md$ ]]; then
  err "$FILE: filename must match NNN-<topic>.md"
fi

if ! head -1 "$FILE" | grep -q '^---$'; then
  err "$FILE: missing YAML frontmatter (opening ---)"
fi

FRONTMATTER="$(
  awk 'NR==1 && /^---$/ {found=1; next} found && /^---$/ {exit} found {print}' "$FILE"
)"

if [[ -z "$FRONTMATTER" ]]; then
  err "$FILE: empty or unclosed frontmatter"
fi

STATUS="$(echo "$FRONTMATTER" | grep -E '^status:' | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '\r' || true)"
if [[ -z "$STATUS" ]]; then
  err "$FILE: frontmatter missing status"
elif [[ ! "$STATUS" =~ ^(draft|approved|done)$ ]]; then
  err "$FILE: status must be draft, approved, or done (got: $STATUS)"
fi

BODY="$(
  awk 'BEGIN{n=0} /^---$/ {n++; if(n==2){found=1; next}} found {print}' "$FILE"
)"

if [[ "$STATUS" == "approved" || "$STATUS" == "done" ]]; then
  if ! echo "$BODY" | grep -qE 'Verification|验证'; then
    err "$FILE: status=$STATUS requires Task Verification section"
  fi
  if ! echo "$BODY" | grep -qE '验证 Checklist|Plan 级'; then
    err "$FILE: status=$STATUS requires Plan-level Checklist section"
  fi
fi

if echo "$BODY" | grep -qiE 'TBD|TODO|后续补'; then
  err "$FILE: contains placeholder (TBD/TODO/后续补)"
fi

if echo "$BODY" | grep -qE '跑一下测试|跑测试|确保没问题|检查一下'; then
  err "$FILE: contains vague verification phrase"
fi

find_repo_root() {
  local dir
  dir="$(cd "$(dirname "$FILE")" && pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/scripts/detect-plan-target.sh" || -f "$dir/.plan-handoff.yaml" || -d "$dir/.git" ]]; then
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

if repo="$(find_repo_root)"; then
  if [[ -x "$repo/scripts/detect-plan-target.sh" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^(PLAN_ROOT|CLAUDE_PLANS_DIR|PLANS_DIR_MISMATCH)= ]] && eval "$line"
    done < <(bash "$repo/scripts/detect-plan-target.sh" "$repo")
    if [[ "${PLANS_DIR_MISMATCH:-0}" == "1" ]]; then
      warn "$FILE: PLAN_ROOT ($PLAN_ROOT) differs from Claude plansDirectory ($CLAUDE_PLANS_DIR)"
    fi
    plan_dir="$(cd "$(dirname "$FILE")" && pwd)"
    expected_dir="$(cd "$repo/$PLAN_ROOT" 2>/dev/null && pwd || true)"
    if [[ -n "$expected_dir" && "$plan_dir" != "$expected_dir" ]]; then
      warn "$FILE: not under detected PLAN_ROOT ($PLAN_ROOT)"
    fi
  fi
fi

if [[ "$ERRORS" -gt 0 ]]; then
  exit 1
fi

echo "ok: $FILE"
exit 0
