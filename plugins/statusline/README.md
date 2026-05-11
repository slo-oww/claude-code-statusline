# statusline (plugin)

Ships `bin/statusline.sh`. Updates are delivered via `/plugin update`.

> **Limitation:** Claude Code plugins cannot declare the main `statusLine` in their own `settings.json` (only `agent` and `subagentStatusLine` are supported). You must wire the script into **your user-level** `~/.claude/settings.json` manually after installing this plugin.

## Activate after install

After `/plugin install statusline@slo-oww-claude-code-statusline`, find the installed plugin root and add it to your user settings.

1. Locate the installed script path (the value of `CLAUDE_PLUGIN_ROOT` shown when the plugin is active, or browse `~/.claude/plugins/`):

   ```text
   ~/.claude/plugins/<cache-id>/plugins/statusline/bin/statusline.sh
   ```

2. Edit `~/.claude/settings.json` and add:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash /absolute/path/to/plugins/statusline/bin/statusline.sh"
     }
   }
   ```

3. Restart Claude Code (or open a new session).

## Requirements

- `jq`
- `awk`

## Why not auto-wire?

The plugin spec only exposes `subagentStatusLine` to plugin authors. The main session statusline is a user-level setting and must be installed by the user explicitly. If you prefer a one-step install, use the curl one-liner described in the [main README](../../README.md#method-b--c-1-curl-one-liner).
