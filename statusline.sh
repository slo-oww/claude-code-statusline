#!/usr/bin/env bash
# Claude Code statusLine — PS1-style location + session metadata
# Requires: jq, awk
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -z "$cwd" ]; then
  cwd=$(pwd)
fi

git_branch=""
if command -v git >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi
user=$(whoami)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
version=$(echo "$input" | jq -r '.version // "unknown"')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

total_tokens=$((input_tokens + output_tokens))
if [ "$total_tokens" -gt 1000 ]; then
  formatted_tokens=$(awk -v t="$total_tokens" 'BEGIN {printf "%.1fk", t/1000}')
else
  formatted_tokens=$total_tokens
fi

ctx_color=$(awk -v p="$context_pct" 'BEGIN {
  if (p+0 > 80)      print "\033[31m"
  else if (p+0 > 60) print "\033[33m"
  else               print "\033[32m"
}')
reset="\033[0m"

if [ -n "$git_branch" ]; then
  loc_fmt='\033[01;32m%s\033[00m:\033[01;34m%s\033[00m (%s)'
  printf "$loc_fmt" "$user" "$cwd" "$git_branch"
else
  loc_fmt='\033[01;32m%s\033[00m:\033[01;34m%s\033[00m'
  printf "$loc_fmt" "$user" "$cwd"
fi

printf ' | \033[1mClaude %s\033[0m | %s | 🪙 %s toks | 🧠 ' \
  "$version" "$model" "$formatted_tokens"
printf '%b%s%%%b' "$ctx_color" "$context_pct" "$reset"
printf ' | ✏️ +%s/-%s' "$lines_added" "$lines_removed"
