#!/usr/bin/env bash
set -euo pipefail
existing=false
if [[ ${1:-} == --help || ${1:-} == -h ]]; then printf '%s\n' 'Usage: bash validate-plan.sh [--existing] PLAN.md'; exit 0; fi
if [[ ${1:-} == --existing ]]; then existing=true; shift; fi
[[ $# == 1 && -f $1 && ! -L $1 ]] || { printf '%s\n' 'error: expected a regular plan file' >&2; exit 2; }
file=$1
parent=$(cd "$(dirname "$file")" && pwd -P)
file=$parent/$(basename "$file")
repo=$(git -C "$parent" rev-parse --show-toplevel) || exit 2
repo=$(cd "$repo" && pwd -P)
helper=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/resolve-plan-target.sh
bash "$helper" --repo "$repo" --existing "${file#"$repo"/}" >/dev/null
if ! $existing; then
  name=$(basename "$file" .md)
  [[ $name == *_* ]] || { echo 'error: new filename must use YYYY-MM-DD_topic.md' >&2; exit 1; }
  relative_parent=${parent#"$repo"/}
  [[ $parent != "$repo" ]] || relative_parent=.
  bash "$helper" --repo "$repo" --plan-root "$relative_parent" --date "${name%%_*}" --topic "${name#*_}" >/dev/null
fi
awk '
function error(message) {print "error: " message > "/dev/stderr"; bad=1}
BEGIN {q=sprintf("%c",39); count=split("背景|参考资料|已确认行为|交付边界|实施步骤|验证|需要决策的问题|下一步",required,"|")}
NR==1 {if($0!="---")error("frontmatter must start with ---"); next}
!closed {
  if($0=="---") {closed=1;next}
  if($0 ~ /^status: (draft|approved|done)$/) {if(status!="")error("duplicate status");status=substr($0,9);next}
  if(index($0,"goal: ")==1) {
    if(goal_seen++)error("duplicate goal")
    value=substr($0,7)
    if(value ~ /\{\{|\}\}/)error("template markers remain")
    if(length(value)<3 || substr(value,1,1)!=q || substr(value,length(value),1)!=q)error("goal must be one single-quoted line")
    else {value=substr(value,2,length(value)-2);gsub(q q,"",value);if(index(value,q))error("escape apostrophes by doubling them");if(value !~ /[^[:space:]]/)error("goal must not be empty")}
    next
  }
  error("unsupported frontmatter; use only status and single-quoted goal");next
}
/\{\{|\}\}/ {error("template markers remain")}
/^## / {section=substr($0,4);if(seen[section]++)error("duplicate section: " section);next}
/[^[:space:]]/ {content[section]=1}
section=="需要决策的问题" {questions=questions $0}
section=="实施步骤" && /^ *- \[[ xX]\]/ {steps++;if($0 !~ /`[^`]+`/)error("step needs a file or module path");if($0 ~ /^ *- \[ \]/)unfinished=1}
section=="验证" && /^ *- / {checks++;if($0 !~ /`[^`]+`/ || ($0 !~ /→|->|预期/))error("verification needs a command and expected result")}
END {
  if(!closed || status=="" || !goal_seen)error("incomplete frontmatter")
  for(i=1;i<=count;i++)if(!content[required[i]])error("missing or empty section: " required[i])
  if(!steps || !checks)error("plan needs steps and verification")
  gsub(/[[:space:]。.]/,"",questions);sub(/^-/,"",questions)
  if(status!="draft" && questions!="无" && questions!="none" && questions!="N/A")error("unresolved questions require draft")
  if(status=="done" && unfinished)error("done plan has unfinished steps")
  exit bad ? 1 : 0
}' "$file"
printf 'ok: %s\n' "$file"
