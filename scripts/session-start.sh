#!/usr/bin/env bash
# session-start.sh
# SessionStart hook: records the Claude session ID on the current wn work item
# (if any), and keeps the wn launcher script and settings template in sync with
# the bundled plugin versions.
# Reads install preferences from ${CLAUDE_PLUGIN_DATA}/config.json.
# No-op for sync if /wn:setup has not been run yet.

# Read hook input from stdin (Claude Code passes session_id here on SessionStart)
HOOK_INPUT=$(cat)

# Resolve plugin root from env var or script's own location as fallback
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Record Claude session ID as a note on the current wn work item (if any).
# Note body is a JSON object so other metadata can be added later without
# changing the note name.
SESSION_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$SESSION_ID" ]; then
  ITEM_ID=$(wn show --json 2>/dev/null | jq -r '.id // empty' 2>/dev/null) || true
  if [ -n "$ITEM_ID" ]; then
    NOTE_BODY=$(jq -n --arg sid "$SESSION_ID" '{"name":"claude","session-id":$sid}')
    wn note add coding-session "$ITEM_ID" -m "$NOTE_BODY" 2>/dev/null || true
  fi
fi

# CLAUDE_PLUGIN_DATA must be set by the hook runner; exit cleanly if not
[ -n "${CLAUDE_PLUGIN_DATA}" ] || exit 0

CONFIG="${CLAUDE_PLUGIN_DATA}/config.json"
[ -f "$CONFIG" ] || exit 0

# Sync launcher script to configured install directory
INSTALL_DIR=$(jq -r '.install_dir // empty' "$CONFIG" 2>/dev/null)
if [ -n "$INSTALL_DIR" ]; then
  INSTALL_DIR=$(eval echo "$INSTALL_DIR")
  SRC="${PLUGIN_ROOT}/scripts/start-wn-tmux-claude"
  DST="${INSTALL_DIR}/start-wn-tmux-claude"
  if ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    mkdir -p "$INSTALL_DIR"
    cp "$SRC" "$DST"
    chmod +x "$DST"
  fi
fi

# Sync settings template if user opted in
AUTO_TPL=$(jq -r '.auto_update_template // "true"' "$CONFIG" 2>/dev/null)
if [ "$AUTO_TPL" = "true" ]; then
  SRC="${PLUGIN_ROOT}/config/wn-worktree-settings.local.json"
  DST="${HOME}/.config/claude/wn-worktree-settings.local.json"
  if ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    mkdir -p "${HOME}/.config/claude"
    cp "$SRC" "$DST"
  fi
fi
