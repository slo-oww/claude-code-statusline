#!/usr/bin/env bash
# Claude Code statusline installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
# Or:
#   bash install.sh
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_PATH="$CLAUDE_DIR/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

echo "📦 Claude Code statusline installer"
echo "   target: $CLAUDE_DIR"
echo ""

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ 'jq' is required but not installed."
  echo "   Ubuntu/WSL: sudo apt install -y jq"
  echo "   macOS:      brew install jq"
  exit 1
fi

if ! command -v awk >/dev/null 2>&1; then
  echo "❌ 'awk' is required but not installed."
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

echo "📝 writing $SCRIPT_PATH"
cat > "$SCRIPT_PATH" <<'STATUSLINE_EOF'
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
STATUSLINE_EOF

chmod +x "$SCRIPT_PATH"

STATUSLINE_CONFIG='{"type":"command","command":"bash $HOME/.claude/statusline.sh"}'

if [ -f "$SETTINGS_PATH" ]; then
  if ! jq empty "$SETTINGS_PATH" >/dev/null 2>&1; then
    echo "❌ $SETTINGS_PATH is not valid JSON. Aborting to avoid data loss."
    exit 1
  fi
  backup="${SETTINGS_PATH}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS_PATH" "$backup"
  echo "🗂  backed up existing settings → $backup"
  tmp=$(mktemp)
  jq --argjson sl "$STATUSLINE_CONFIG" '.statusLine = $sl' "$SETTINGS_PATH" > "$tmp"
  mv "$tmp" "$SETTINGS_PATH"
  echo "🔧 merged statusLine into $SETTINGS_PATH"
else
  echo "{}" | jq --argjson sl "$STATUSLINE_CONFIG" '.statusLine = $sl' > "$SETTINGS_PATH"
  echo "🆕 created $SETTINGS_PATH"
fi

echo ""
echo "🧪 verification:"
echo '{"cwd":"'"$PWD"'","model":{"display_name":"Test"},"version":"x","context_window":{"used_percentage":50,"current_usage":{"input_tokens":100,"output_tokens":50}},"cost":{"total_lines_added":0,"total_lines_removed":0}}' \
  | bash "$SCRIPT_PATH"
echo ""
echo ""
echo "✅ Done. Next Claude Code session will pick up the new statusline."
