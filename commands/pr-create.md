---
description: Push the current feature branch and open a pull request, then record the PR URL on the wn item. Use after /wn:implement when the user invokes "/wn:pr-create".
argument-hint: [item-id]
---

Push the current feature branch to the remote and create a pull request. Run each step in sequence — stop and report if anything fails.

## Step 0: Check for gh CLI

```bash
gh auth status
```

If this fails, stop and tell the user: "`gh` CLI is required and must be authenticated. Run `gh auth login` to set it up, then retry."

## Step 1: Identify the branch and work item

```bash
git rev-parse --abbrev-ref HEAD
```

This is the `<branch>`.

**If `$ARGUMENTS` is a non-empty item ID:** use it as the wn item ID.

**If no argument was given:**
- Call `wn_note_search` with `name: "wn:branch"`, `value: "<branch>"`, `first: true` to find the item whose `wn:branch` note matches the current branch.
- If no match is found, stop and tell the user: "Could not find a wn item associated with branch `<branch>`. Pass the item ID as an argument."

Store the result as `<item-id>`.

## Step 2: Ensure review-ready

Call `wn_show` with `<item-id>` to read the current item state.

If the item has an active claim (not yet released), call `wn_release` to clear the claim and mark it review-ready. If already released (no active claim), skip.

## Step 3: Push branch

```bash
git push -u origin <branch>
```

If this fails (e.g. no remote configured, auth error), stop and report the error.

## Step 4: Create pull request

Compose the PR:
- **Title:** the wn item title (from `wn_show`)
- **Body:** the wn item description, followed by a blank line, then `wn item: <item-id>`

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<description>

wn item: <item-id>
EOF
)"
```

Capture the PR URL from the output (printed by `gh pr create`).

## Step 5: Record PR reference on the item

```bash
wn note add wn:pr <item-id> -m "<pr-url>"
```

## Step 6: Report

Tell the user:
- PR URL
- Branch pushed: `<branch>`
- wn item: `<item-id>` (title)
- Next step: after the PR is reviewed and merged on GitHub, run `/wn:pr-close` to record the commit and mark the item done
