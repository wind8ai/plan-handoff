#!/usr/bin/env bash
set -euo pipefail
fail() { printf 'error: %s\n' "$*" >&2; exit 2; }
repo=.; directory=plans; date_value=; topic=; existing=
while (($#)); do
  case "$1" in
    --help|-h) printf '%s\n' 'Usage: bash resolve-plan-target.sh [--repo DIR] [--plan-root REL] --date YYYY-MM-DD --topic TOPIC' '       bash resolve-plan-target.sh [--repo DIR] --existing REL'; exit 0 ;;
    --repo|--plan-root|--date|--topic|--existing) (($# >= 2)) || fail "missing value for $1"; key=$1; value=$2; shift 2
      case "$key" in --repo) repo=$value;; --plan-root) directory=$value;; --date) date_value=$value;; --topic) topic=$value;; --existing) existing=$value;; esac ;;
    *) fail "unknown argument: $1" ;;
  esac
done
repo=$(git -C "$repo" rev-parse --show-toplevel) || fail 'not inside a repository working directory'
repo=$(cd "$repo" && pwd -P)
if [[ -n $existing ]]; then
  [[ -z $date_value && -z $topic ]] || fail '--existing cannot be combined with date/topic'
  relative=$existing; mode=update
else
  [[ $date_value =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail 'date must be YYYY-MM-DD'
  awk -v d="$date_value" 'BEGIN {split(d,a,"-"); y=a[1]+0;m=a[2]+0;n=a[3]+0; days=31;if(m==4||m==6||m==9||m==11)days=30;if(m==2)days=28+(y%4==0&&(y%100!=0||y%400==0));exit !(y>=1&&m>=1&&m<=12&&n>=1&&n<=days)}' || fail 'invalid calendar date'
  [[ -n $topic && $topic != -* && $topic != *- && $topic != *--* && $topic != *[![:alnum:]-]* && $topic != *[A-Z]* ]] || fail 'topic must use letters/numbers and single hyphens; English lowercase'
  relative=$directory/${date_value}_${topic}.md; mode=create
fi
[[ $relative != /* && $relative != *$'\n'* && $relative != *$'\r'* ]] || fail 'use a repository-relative path without newlines'
# Walk components without following symlinks or permitting parent traversal.
current=$repo
IFS=/ read -r -a parts <<< "$relative"
for part in "${parts[@]}"; do
  [[ -n $part && $part != . ]] || continue
  [[ $part != .. ]] || fail 'parent traversal is not allowed'
  current=$current/$part
  [[ ! -L $current ]] || fail 'symlink paths are not supported'
done
if [[ -n $existing ]]; then
  [[ -f $current && $current == *.md ]] || fail 'existing plan must be a Markdown file'
elif [[ -e $current ]]; then
  [[ -f $current ]] || fail 'target exists and is not a file'
  mode=review
fi
if git -C "$repo" check-ignore -q -- "${current#"$repo"/}"; then fail 'plan path is ignored by Git'; else rc=$?; [[ $rc == 1 ]] || fail 'could not check Git ignore rules'; fi
printf 'repo_root=%s\nplan_file=%s\ntarget_mode=%s\n' "$repo" "$current" "$mode"
