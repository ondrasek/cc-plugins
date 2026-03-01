---
type: reference
used_by: review-pr
description: Detailed specification of the poll-diagnose-fix-push loop that drives PR review iteration.
---

# Loop Workflow

The review-pr skill uses a poll-diagnose-fix-push loop to shepherd a PR from "open" to "mergeable". Each iteration checks CI, reviews, and threads, then takes the appropriate action.

## Loop Structure

```
for iteration in 1..MAX_ITERATIONS (default 5):
    1. Poll CI checks
    2. Poll review decision
    3. Poll unresolved review threads (GraphQL)
    4. Evaluate exit conditions
    5. If not exiting: diagnose → fix → push → continue
```

## Step 1: Poll CI Checks

```bash
gh pr checks --json name,state,bucket,link
```

### Check states

| `state` | Meaning |
|---------|---------|
| `SUCCESS` | Check passed |
| `FAILURE` | Check failed — needs fixing |
| `PENDING` | Check still running |
| `NEUTRAL` | Informational, not blocking |
| `SKIPPED` | Check skipped |

### Handling pending checks

If any checks are `PENDING` and none are `FAILURE`:
1. Wait with exponential backoff: 15s, 30s, 60s, 120s (cap)
2. Re-poll after each wait
3. After 10 minutes of total waiting, ask the user whether to continue waiting or bail

```bash
# Re-poll after waiting
sleep $BACKOFF_SECONDS
gh pr checks --json name,state,bucket,link
```

## Step 2: Poll Review Decision

```bash
gh pr view --json reviewDecision,reviews
```

### Review decisions

| `reviewDecision` | Meaning |
|-----------------|---------|
| `APPROVED` | At least one approving review, no changes requested |
| `CHANGES_REQUESTED` | At least one review requesting changes |
| `REVIEW_REQUIRED` | Reviews required but none submitted |
| `""` (empty) | No review policy configured |

## Step 3: Poll Unresolved Threads

Use the GraphQL query from `references/graphql-queries.md` to fetch all review threads. Filter for `isResolved == false`.

## Step 4: Exit Conditions

### Success — PR is ready to merge

All of these must be true:
- All CI checks are `SUCCESS` (or `NEUTRAL`/`SKIPPED`)
- Review decision is `APPROVED` or empty (no review policy)
- Zero unresolved review threads

### Blocked on reviewer

- Unresolved threads exist where the **last comment is from us** (we replied but reviewer hasn't responded)
- No CI failures to fix
- Action: report which threads are waiting on reviewer, exit the loop

### Max iterations reached

- Loop counter exceeds MAX_ITERATIONS
- Action: report remaining failures/threads, ask user whether to continue (reset counter) or stop

## Step 5: Diagnose and Fix

### 5a. CI Failures

For each failed check:

1. **Get the run ID**:
   ```bash
   gh pr checks --json name,state,link | jq -r '.[] | select(.state == "FAILURE")'
   ```

2. **Read failed logs**:
   ```bash
   # Extract run ID from the check link URL
   gh run view RUN_ID --log-failed
   ```

3. **Categorize the failure**:
   | Category | Indicators |
   |----------|-----------|
   | Lint | eslint, ruff, clippy, stylelint, pylint |
   | Test | pytest, jest, cargo test, dotnet test |
   | Build | compile error, build failed, tsc |
   | Type check | mypy, pyright, tsc --noEmit |
   | Security | bandit, npm audit, cargo deny |
   | Unknown | Anything else |

4. **Fix the code** — read the relevant files, understand the error, apply the fix

5. **Commit with issue reference**:
   ```bash
   git add <changed-files>
   git commit -m "fix: address <category> failure in <check-name> (#N)"
   ```

6. **Push**:
   ```bash
   git push
   ```

### 5b. Unresolved Review Threads

For each unresolved thread (from GraphQL response):

1. **Read the thread**: note the file path, line number, and reviewer's comment
2. **Read the file**: open the file at the referenced line to understand context
3. **Determine response type**:

   | Situation | Action |
   |-----------|--------|
   | Code fix needed | Make the fix, reply "Fixed in `<sha-short>`. <explanation>", resolve the thread |
   | Style/naming suggestion | Apply the suggestion, reply "Applied — good catch.", resolve the thread |
   | Reviewer asks a question | Reply with explanation, do NOT resolve (leave for reviewer) |
   | Disagreement on approach | Reply with reasoning, do NOT resolve (leave for reviewer) |
   | Outdated thread (`isOutdated`) | Assess if feedback still applies. If already fixed, reply "This was addressed in `<sha>`. The code has changed since this comment." and resolve. If still relevant, treat as above. |

4. **Reply to the thread** (GraphQL mutation from `references/graphql-queries.md`)
5. **Resolve the thread** (only for code fixes — GraphQL mutation)

6. **Commit all fixes together**:
   ```bash
   git add <changed-files>
   git commit -m "fix: address review feedback (#N)"
   ```

7. **Push**:
   ```bash
   git push
   ```

### 5c. Merge Conflicts

```bash
# Check for merge conflicts
gh pr view --json mergeable,mergeStateStatus
```

| `mergeStateStatus` | Action |
|-------------------|--------|
| `CLEAN` | No conflicts, proceed |
| `DIRTY` | Merge conflicts exist — escalate to user |
| `BLOCKED` | Branch protection rules blocking merge — inform user |
| `UNSTABLE` | Some checks failing but mergeable — continue fixing |

**If conflicts detected**: stop the loop, report the conflicting files, and ask the user to resolve manually. Do NOT attempt to auto-resolve merge conflicts.

## Iteration Budget

- Default: 5 iterations
- Each iteration may include one commit+push (CI fix) and/or one commit+push (review feedback)
- After MAX_ITERATIONS, report status and ask user:
  - "Continue for N more iterations?"
  - "Stop and address remaining issues manually?"
- User can also set a custom iteration limit

## Wait Budget

- Total wait time for pending checks: 10 minutes
- Backoff schedule: 15s → 30s → 60s → 120s (repeating)
- After 10 minutes, ask user before waiting longer
