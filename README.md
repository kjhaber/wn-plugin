# wn-plugin

A Claude Code plugin with skills and scripts to accompany [`wn`](https://github.com/kjhaber/wn), the "What's Next" CLI work item manager.

## Skills

| Skill | Description |
|---|---|
| `/wn:setup` | First-time setup: installs wn, registers the MCP server, installs the tmux-claude launcher, and configures wn settings |
| `/wn:implement` | Claim a wn work item and implement it with red/green TDD — handles branching, testing, committing, and marking review-ready |
| `/wn:merge` | Squash-merge the current feature branch into main and mark the item done |

## Installation

### From GitHub

Add this repo as a plugin marketplace, then install:

```
/plugin marketplace add kjhaber/wn-plugin
/plugin install wn@kjhaber/wn-plugin
```

### Local development

Load directly without installing:

```
claude --plugin-dir /path/to/wn-plugin
```

Then run `/wn:setup` to complete configuration.

## Setup

`/wn:setup` walks through:

1. Installing `wn` (macOS: `brew install kjhaber/tap/wn`) if not found
2. Registering the `wn` MCP server with Claude Code
3. Choosing an install directory for the `start-wn-tmux-claude` launcher script (default: `~/.local/bin`)
4. Opting in or out of auto-updating the worktree permissions template
5. Configuring the `tmux-claude` runner in `wn settings`

Re-run `/wn:setup` at any time to reconfigure.

## tmux-claude launcher

`start-wn-tmux-claude` opens Claude Code in a new tmux window for a wn work item. It:

- Creates a named tmux window (`wn-<item-id>`) and switches to it if it already exists
- Generates a `settings.local.json` in the worktree's `.claude/` directory with permissions scoped to that worktree
- Launches Claude Code with `/wn:implement <item-id>` as the initial prompt

Once setup is complete, launch it with:

```
wn launch tmux-claude
```

### Auto-update

The plugin's `SessionStart` hook keeps `start-wn-tmux-claude` and the worktree permissions template in sync with the bundled plugin versions on every Claude Code startup. Update behavior is controlled by `~/.claude/plugins/data/wn/config.json`:

```json
{
  "install_dir": "~/.local/bin",
  "auto_update_template": true
}
```

Set `auto_update_template` to `false` if you want to customize `~/.config/claude/wn-worktree-settings.local.json` without it being overwritten.

## License

MIT
