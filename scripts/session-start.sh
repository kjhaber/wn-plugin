#!/usr/bin/env bash
# session-start.sh
# SessionStart hook: keeps the wn launcher script and settings template
# in sync with the bundled plugin versions.
# Reads install preferences from ${CLAUDE_PLUGIN_DATA}/config.json.
# No-op if /wn:setup has not been run yet.

CONFIG="${CLAUDE_PLUGIN_DATA}/config.json"
[ -f "$CONFIG" ] || exit 0

# Sync launcher script to configured install directory
INSTALL_DIR=$(jq -r '.install_dir // empty' "$CONFIG" 2>/dev/null)
if [ -n "$INSTALL_DIR" ]; then
  INSTALL_DIR=$(eval echo "$INSTALL_DIR")
  SRC="${CLAUDE_PLUGIN_ROOT}/scripts/start-wn-tmux-claude"
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
  SRC="${CLAUDE_PLUGIN_ROOT}/config/wn-worktree-settings.local.json"
  DST="${HOME}/.config/claude/wn-worktree-settings.local.json"
  if ! diff -q "$SRC" "$DST" >/dev/null 2>&1; then
    mkdir -p "${HOME}/.config/claude"
    cp "$SRC" "$DST"
  fi
fi
