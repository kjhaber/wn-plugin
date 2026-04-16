.PHONY: all lint shellcheck json-validate test

all: lint test

lint: shellcheck json-validate

shellcheck:
	shellcheck scripts/session-start.sh
	shellcheck tests/test-session-start.sh
	zsh -n scripts/start-wn-tmux-claude

test:
	bash tests/test-session-start.sh

json-validate:
	@for f in hooks/hooks.json settings.json .mcp.json \
	           .claude-plugin/plugin.json .claude-plugin/marketplace.json \
	           config/wn-worktree-settings.local.json; do \
	    echo "Validating $$f..."; \
	    jq empty "$$f" || exit 1; \
	done
	@# plugin.json: required fields
	@jq -e '.name and .version and .description' .claude-plugin/plugin.json >/dev/null \
	    || (echo "ERROR: plugin.json missing required field (name/version/description)" && exit 1)
	@# marketplace.json: description must be in metadata (not top-level)
	@jq -e '.metadata.description' .claude-plugin/marketplace.json >/dev/null \
	    || (echo "ERROR: marketplace.json description must be under .metadata.description" && exit 1)
	@jq -e 'if .description then error("top-level description not allowed in marketplace.json") else . end' \
	    .claude-plugin/marketplace.json >/dev/null \
	    || exit 1
	@# marketplace.json: plugin source paths must start with ./
	@jq -e 'all(.plugins[]; .source | startswith("./"))' \
	    .claude-plugin/marketplace.json >/dev/null \
	    || (echo "ERROR: marketplace.json plugin source path must start with ./" && exit 1)
	@echo "All JSON valid."
