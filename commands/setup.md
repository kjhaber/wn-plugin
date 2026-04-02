---
description: Set up the wn Claude Code plugin — installs wn if needed, registers the wn MCP server, configures the tmux-claude launcher script, and walks through wn settings. Re-run at any time to reconfigure.
---

Configure the wn Claude Code plugin for this machine. Run each step in sequence.

## Step 1: Check for wn

Run:
```bash
command -v wn
```

**If found:** note the version with `wn --version` and continue.

**If not found:** Tell the user that `wn` is required and offer to install it:
- On macOS with Homebrew: `brew install kjhaber/tap/wn`
- Otherwise, direct them to https://github.com/kjhaber/wn for installation instructions.

If the user declines installation, stop and explain that setup cannot continue without `wn`.

## Step 2: Register the wn MCP server

The wn MCP server must be registered so that Claude Code can use `wn_settings_get`, `wn_settings_set`, and other wn tools.

Ask the user to run the following command (it cannot be run by Claude directly, as MCP registration requires user action in the Claude Code UI):

> Please run this command to register the wn MCP server at user scope:
> ```
> claude mcp add wn --scope user -- wn mcp
> ```
> Then restart Claude Code and re-run `/wn:setup` to continue.

Once they confirm the MCP is registered and Claude has been restarted, verify by calling `wn_settings_get` with key `sort`. If the call succeeds, the MCP is live. If it fails, remind the user to restart Claude Code.

## Step 3: Load existing config

Read `${CLAUDE_PLUGIN_DATA}/config.json` if it exists. Use its current values as defaults for the prompts below.

## Step 4: Configure launcher script install location

Ask the user:
> Where should the `start-wn-tmux-claude` launcher script be installed?
> This directory must be in your PATH so `wn launch` can find it.
> [default: ~/.local/bin]

Accept a path. Expand `~` to the home directory.

Verify the directory is in PATH:
```bash
echo "$PATH" | tr ':' '\n' | grep -qxF "<expanded_path>"
```

If it's not in PATH, warn the user: *"<path> does not appear to be in your PATH. The launcher will be installed there, but `wn launch tmux-claude` won't work until it's added to PATH."*

## Step 5: Configure settings template auto-update

Ask the user:
> Auto-update the wn-worktree-settings template when the plugin updates?
> Say no if you plan to customize ~/.config/claude/wn-worktree-settings.local.json.
> [Y/n]

## Step 6: Write config and install files

Write `${CLAUDE_PLUGIN_DATA}/config.json`:
```json
{
  "install_dir": "<chosen path>",
  "auto_update_template": <true|false>
}
```

Install the launcher script:
```bash
mkdir -p <install_dir>
cp "${CLAUDE_PLUGIN_ROOT}/scripts/start-wn-tmux-claude" "<install_dir>/start-wn-tmux-claude"
chmod +x "<install_dir>/start-wn-tmux-claude"
```

If `auto_update_template` is true, install the settings template:
```bash
mkdir -p ~/.config/claude
cp "${CLAUDE_PLUGIN_ROOT}/config/wn-worktree-settings.local.json" ~/.config/claude/wn-worktree-settings.local.json
```
If the template already exists at the destination, overwrite it (the user just said they want auto-updates).

## Step 7: Configure wn runner

Check whether the tmux-claude runner is already configured using the MCP tool:
- Call `wn_settings_get` with key `runners.tmux-claude`

If already configured, show the current value and ask: *"The tmux-claude runner is already configured. Update it? [y/N]"* — skip if they say no.

If not configured (or user wants to update), set the runner via MCP:
- Call `wn_settings_set` with key `runners.tmux-claude.cmd`, value `start-wn-tmux-claude {{.Worktree}} {{.ItemID}}`, scope `user`
- Call `wn_settings_set` with key `runners.tmux-claude.leave_worktree`, value `true`, scope `user`

## Step 8: Report

Tell the user:
- wn version found (or just installed)
- MCP server registered: yes/already present
- Launcher script installed to: `<install_dir>/start-wn-tmux-claude`
- Settings template: auto-update on/off
- wn runner configured: yes/skipped
- How to launch: `wn launch tmux-claude` from any wn-managed repo
- How to re-run this setup: `/wn:setup`
