---
description: Confirm a pull request is merged, record the commit, and mark the wn item done. Use after the PR is merged on GitHub when the user invokes "/wn:pr-close".
argument-hint: [item-id]
---

Confirm the pull request is merged on GitHub, record the merge commit, and mark the wn item done. Run each step in sequence — stop and report if anything fails.

## Step 0: Check for gh CLI

```bash
gh auth status
```

If this fails, stop and tell the user: "`gh` CLI is required and must be authenticated. Run `gh auth login` to set it up, then retry."

## Step 1: Resolve the work item and PR

**If `$ARGUMENTS` is a non-empty item ID:** use it as `<item-id>`. Look up the `wn:pr` note to find the PR URL:
```bash
wn note show <item-id> wn:pr
```

**If no argument was given:**
- Read the current branch: `git rev-parse --abbrev-ref HEAD`
- Call `wn_note_search` with `name: "wn:branch"`, `value: "<branch>"`, `first: true` to find the associated item.
- If no item found, stop and tell the user: "Could not identify a wn item from the current branch. Pass the item ID as an argument."

If the item has a `wn:pr` note, extract the PR URL/number from it.

If no `wn:pr` note exists (PR was created outside of `/wn:pr-create`), attempt auto-detection:
```bash
gh pr list --head <branch> --json number,url,state --limit 1
```
Use the result if exactly one PR is found; otherwise, stop and ask the user to provide the item ID explicitly.

Store as `<item-id>` and `<pr-ref>` (URL or number).

## Step 2: Verify the PR is merged

```bash
gh pr view <pr-ref> --json state,mergeCommit,baseRefName
```

Parse the response:
- If `state` is not `"MERGED"`, stop and tell the user: "PR `<pr-ref>` is not merged yet (state: `<state>`). Merge it on GitHub first, then re-run `/wn:pr-close`."
- Extract `mergeCommit.oid` as `<merge-commit>`.
- Extract `baseRefName` as `<main-branch>` (e.g. `main` or `master`).

## Step 3: Pull main

```bash
git checkout <main-branch>
git pull origin <main-branch>
```

If checkout or pull fails, stop and report.

## Step 4: Verify main is green

```bash
wn verify --root
```

If it fails, report the failure **but continue** — the code is already merged; the user needs the information but should not be blocked from closing the item.

## Step 5: Record merge commit and mark done

```bash
wn note add wn:commit <item-id> -m "<merge-commit>"
```

Then call `wn_done` with `<item-id>`.

## Step 6: Report

Tell the user:
- Item `<item-id>` marked done
- Merge commit recorded: `<merge-commit>`
- Main branch pulled to: `<main-branch>`
- If `wn verify` failed in step 4, surface that warning here
- Optional cleanup: `git branch -d <feature-branch>` (if still on the machine) and `git push origin --delete <feature-branch>`
