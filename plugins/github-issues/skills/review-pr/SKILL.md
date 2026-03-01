---
name: review-pr
description: Shepherd a pull request through CI checks and code review to merge — poll checks, fix failures, address review feedback, resolve threads, push updates. Use when user says "review my PR", "get this PR merged", "fix CI", "address review comments", "check PR status", "what's blocking my PR", "resolve review threads", or wants to iterate a PR to green.
---

# Review PR

Shepherds a pull request from open to merged: finds or creates a PR, then loops — polling CI checks and review comments, fixing failures, addressing feedback, pushing, and re-polling — until the PR is green and approved.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Never run on main/master** — refuse and explain why
- **Never auto-resolve reviewer questions or disagreements** — only resolve threads after making a code fix
- **Never auto-resolve merge conflicts** — escalate to the user
- **Always include `#N` issue reference** in commit messages (existing hook enforces this)
- **Max 5 loop iterations** by default — ask user before continuing beyond that
- **GraphQL for review threads** — REST API does not expose `isResolved`; see `references/graphql-queries.md`

## Prerequisites Check

```bash
# 1. Must NOT be on main/master
BRANCH=$(git branch --show-current)
# If main or master → stop with error

# 2. Check for uncommitted changes
git status --porcelain

# 3. Verify gh authentication
gh auth status
```

If uncommitted changes exist, warn the user and ask: stash, commit, or abort.

## Phase 1: Ensure PR Exists

### Check for existing PR

```bash
gh pr view --json number,url,title,state,baseRefName,isDraft,reviewDecision,statusCheckRollup
```

### Decision tree

| Result | Action |
|--------|--------|
| PR exists, OPEN | Proceed to Phase 2 |
| PR exists, MERGED | Inform user: "This PR was already merged." Stop. |
| PR exists, CLOSED | Inform user: "This PR was closed." Ask to reopen or stop. |
| No PR exists | Create one (see below) |

### Creating a new PR

1. **Push the branch**:
   ```bash
   git push -u origin HEAD
   ```

2. **Detect linked issue** from branch name (`<number>-<description>` convention):
   ```bash
   # Extract issue number from branch name
   ISSUE_NUMBER=$(echo "$BRANCH" | grep -oE '^[0-9]+')
   ```

3. **Get default branch**:
   ```bash
   gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'
   ```

4. **Create the PR**:
   ```bash
   gh pr create --fill --base "$DEFAULT_BRANCH"
   ```
   If an issue was detected, ensure the PR body includes `Closes #N`.

5. **Comment on linked issue**:
   ```bash
   gh issue comment "$ISSUE_NUMBER" --body "PR opened: $PR_URL"
   ```

### Draft PR warning

If the PR is a draft (`isDraft: true`):
- Warn: "This PR is a draft. Reviews and some checks may not trigger until it's marked ready."
- Offer to mark ready:
  ```bash
  gh pr ready
  ```

## Phase 2: The Loop

Read the detailed loop specification: `references/loop-workflow.md`

### Summary

Each iteration (max 5 by default):

1. **Poll CI checks**: `gh pr checks --json name,state,bucket,link`
2. **Poll review decision**: `gh pr view --json reviewDecision`
3. **Poll unresolved threads**: GraphQL query (see `references/graphql-queries.md`)
4. **Check merge conflicts**: `gh pr view --json mergeable,mergeStateStatus`
5. **Evaluate exit conditions**:
   - All checks pass + approved (or no review policy) + 0 unresolved threads = **success**
   - Unresolved threads where we replied last = **blocked on reviewer**
   - Merge conflicts = **escalate to user**
6. **If not exiting**: fix CI failures and/or address review feedback, commit, push, continue loop

### Fixing CI failures

1. Read failed check logs: `gh run view RUN_ID --log-failed`
2. Categorize: lint, test, build, type-check, security, unknown
3. Read relevant files, understand the error, apply the fix
4. Commit: `git commit -m "fix: address CI failure in <check> (#N)"`
5. Push: `git push`

### Addressing review threads

For each unresolved thread:

1. Read the thread (file path, line, reviewer comment)
2. Read the file at the referenced location
3. Determine response:
   - **Code fix needed**: make fix, reply "Fixed in `<sha>`.", resolve thread (GraphQL)
   - **Question/disagreement**: reply with reasoning, do NOT resolve (leave for reviewer)
4. Commit all review fixes: `git commit -m "fix: address review feedback (#N)"`
5. Push: `git push`

### Pending checks

- Wait with exponential backoff: 15s → 30s → 60s → 120s cap
- After 10 minutes total waiting, ask the user whether to continue or bail

## Phase 3: Terminal State

### Success

The PR is green and approved (or no review policy).

1. **Report status**:
   - PR URL and title
   - Review decision
   - All checks passed

2. **Offer to merge**:
   ```bash
   # Ask user which merge strategy to use
   gh pr merge --squash  # or --merge, --rebase
   ```

3. **Comment on linked issue** (if detected):
   ```bash
   gh issue comment "$ISSUE_NUMBER" --body "PR #$PR_NUMBER is green and approved. Merging."
   ```

### Max iterations reached

1. Report remaining failures and unresolved threads
2. Ask user:
   - "Continue for N more iterations?"
   - "Stop and address remaining issues manually?"

### Blocked on reviewer

1. Report which threads are waiting on reviewer response
2. List the thread paths, lines, and last comment
3. Exit — nothing more to do until reviewer responds

### Merge conflicts

1. Report conflicting state
2. Ask user to resolve manually
3. Exit the loop

## Examples

### Example 1: Simple — PR exists, CI failing

```
User: "review my PR"
→ Detect branch, find existing PR #15
→ Poll: 2 checks failing (lint + test), no reviews yet
→ Read lint logs → fix import order → commit "fix: address lint failure (#7)"
→ Read test logs → fix assertion → commit "fix: address test failure (#7)"
→ Push
→ Re-poll: all checks pass, no reviewers assigned
→ Report: "PR #15 is green. No reviewers assigned. Ready to merge."
→ Offer to merge
```

### Example 2: Review feedback

```
User: "get this PR merged"
→ PR #22 exists, checks pass, 3 unresolved review threads
→ Thread 1: "rename this variable" → apply, reply, resolve
→ Thread 2: "add error handling here" → add try/catch, reply, resolve
→ Thread 3: "why not use library X?" → reply with reasoning, do NOT resolve
→ Commit "fix: address review feedback (#12)", push
→ Re-poll: checks pass, 1 unresolved thread (waiting on reviewer)
→ Report: "Addressed 2 of 3 threads. Thread on line 45 of src/api.ts is waiting on reviewer response."
```

### Example 3: No PR yet

```
User: "review my PR" (on branch 42-add-auth)
→ No PR found
→ Push branch, create PR with "Closes #42" in body
→ Comment on issue #42: "PR opened: <url>"
→ Poll: checks pending → wait → checks pass, no reviews
→ Report: "PR #23 created and checks are green. No reviewers assigned."
```

## Troubleshooting

**`gh pr checks` returns empty**:
- CI may not be configured for this repo. Inform the user and treat as "all checks pass".

**GraphQL query fails**:
- Verify `gh auth status` has the `repo` scope.
- Ensure the PR number is correct.

**Cannot determine issue number from branch**:
- Branch doesn't follow `<number>-<description>` convention. Proceed without issue linking.
- Ask the user if they want to link to a specific issue.

**Check logs too large to read**:
- Focus on the first error in the log output.
- Use `--log-failed` which only shows failing steps, not the full log.

**Review threads reference deleted/moved code**:
- The `isOutdated` flag indicates the code has changed. Assess whether the feedback still applies.
