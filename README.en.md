**🌐 Languages:** [日本語](README.md) · **English** · [한국어](README.ko.md)

# claude-code-statusline

A custom [Claude Code](https://docs.claude.com/en/docs/claude-code) statusline that shows:

- Current user · working directory · git branch (PS1-style)
- Claude version · model name
- Token usage (formatted, e.g. `12.8k`)
- Context window usage % (color-coded: 🟢 ≤60% / 🟡 61–80% / 🔴 >80%)
- Code changes for the session (`+lines / -lines`)

## Preview

```
myuser:/home/myuser/proj (main) | Claude 2.1.140 | Claude Opus 4.7 | 🪙 12.8k toks | 🧠 42.5% | ✏️ +127/-43
```

## Requirements

- `jq` — JSON parser (the statusline reads JSON from stdin)
- `awk` — for number formatting and color thresholds
- Bash 4+ (works in WSL and Git Bash on Windows; native cmd/PowerShell is **not** supported)

```bash
# Ubuntu/WSL
sudo apt install -y jq

# macOS
brew install jq
```

---

## Installation

Three installation paths are supported. **Method B** (curl one-liner) is recommended for most users.

### Method A — Manual file copy

For users who want to read every line before installing.

1. Download the script:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/statusline.sh \
     -o ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. Add this block to `~/.claude/settings.json` (merge with existing settings if any):

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash $HOME/.claude/statusline.sh"
     }
   }
   ```

3. Restart Claude Code or start a new session.

### Method B / C-1 — Curl one-liner (recommended)

Single command. Auto-installs the script, merges `statusLine` into your settings (backing up the existing file), and verifies the output.

```bash
curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

What it does:

- Writes `~/.claude/statusline.sh` (+ executable permission)
- Merges `statusLine` into `~/.claude/settings.json` — **other keys are preserved**
- Existing `settings.json` is backed up as `settings.json.bak.YYYYMMDDHHMMSS`
- Aborts safely if existing `settings.json` is invalid JSON
- Prints a verification line so you know it works before opening a new session

Custom install location via env var:

```bash
CLAUDE_DIR=$HOME/my-claude curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

### Method C-2 — Plugin via marketplace

Use this if you want script updates delivered via `/plugin update`. **You still need to manually edit `settings.json`** because Claude Code's plugin spec does not allow plugins to declare the main `statusLine` (only `subagentStatusLine` is exposed to plugin authors).

1. Inside a Claude Code session, add this marketplace:

   ```text
   /plugin marketplace add slo-oww/claude-code-statusline
   ```

2. Install the plugin:

   ```text
   /plugin install statusline@slo-oww-claude-code-statusline
   ```

3. Find where Claude Code installed the plugin:

   ```bash
   find ~/.claude/plugins -name 'statusline.sh' 2>/dev/null
   ```

4. Add the absolute path to `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash /absolute/path/from/step-3"
     }
   }
   ```

5. Restart Claude Code.

Future updates: `/plugin update` will refresh the script, but your `settings.json` does not need re-editing.

---

## Color Coding

The context % is colored based on usage:

| Range  | Color   | Meaning                           |
|--------|---------|-----------------------------------|
| ≤ 60%  | 🟢 Green | Plenty of headroom                |
| 61–80% | 🟡 Yellow | Watch usage; consider `/compact` |
| > 80%  | 🔴 Red   | High — compact or end session soon |

Thresholds are in `statusline.sh` (look for the `awk -v p="$context_pct"` block) and can be tuned to taste.

## JSON Fields Consumed

The script reads these fields from the JSON Claude Code passes on stdin (schema as of v2.1.132+):

- `.cwd`
- `.model.display_name`
- `.version`
- `.context_window.used_percentage`
- `.context_window.current_usage.input_tokens`
- `.context_window.current_usage.output_tokens`
- `.cost.total_lines_added`
- `.cost.total_lines_removed`

All fields use `// 0` or `// "default"` defaults via jq, so the script degrades gracefully if Claude Code's schema changes.

## Uninstall

```bash
# Remove the script
rm ~/.claude/statusline.sh

# Remove the statusLine key from settings.json (keeps other settings intact)
tmp=$(mktemp) && jq 'del(.statusLine)' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json

# If installed via plugin marketplace
# /plugin uninstall statusline@slo-oww-claude-code-statusline
# /plugin marketplace remove slo-oww/claude-code-statusline
```

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| Status line is empty | `jq` not installed → `apt install jq` or `brew install jq` |
| Context % shows `0%` | The session has not made an API call yet (`current_usage` is null until first response) |
| Colors not rendering | Terminal does not support ANSI escapes — check `TERM` env var |
| `~` not expanding in settings.json | Use `$HOME` instead of `~` — both work in shell but `$HOME` is more reliable |
| `is not valid JSON` (installer) | `~/.claude/settings.json` has a syntax error — fix manually, then re-run |

## Contributing

The statusline script is duplicated in three places to support the three installation methods. **When changing script behavior, update all three** and commit together:

- `statusline.sh` (root, used by Method A direct download)
- `install.sh` (heredoc body, used by Method B curl one-liner)
- `plugins/statusline/bin/statusline.sh` (used by Method C-2 plugin)

A simple sync check:

```bash
diff statusline.sh plugins/statusline/bin/statusline.sh && echo "✅ in sync"
```

PRs welcome.

## License

MIT — see [LICENSE](LICENSE).
