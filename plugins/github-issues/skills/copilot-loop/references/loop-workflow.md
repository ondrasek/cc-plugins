---
type: reference
used_by: copilot-loop
description: Detailed specification of the request-poll-fix-push iteration loop that drives a PR to a Copilot-clean state.
---

# Loop Workflow

The copilot-loop skill drives a PR to "Copilot-clean" via a request-poll-fix-push iteration. Each iteration ends in one of: success (no comments), continue (comments addressed and pushed), or escalate (max iterations / false positives only).

## Loop Structure

```
state:
  PR_NUMBER, PR_NODE_ID
  LAST_REVIEWED_SHA   # the HEAD Copilot last reviewed (None initially)
  PUSHED_SINCE_REQUEST = false
  unresolved_pushed_back = []   # comments we replied to but did NOT fix

for iteration in 1..MAX_ITERATIONS (default 5):
    1. Determine HEAD SHA
    2. If LAST_REVIEWED_SHA != HEAD_SHA: request Copilot review (re-request)
    3. Poll until Copilot's review of HEAD_SHA lands (5-min budget)
    4. Read review comments
    5. If 0 comments AND review body non-blocking → SUCCESS
    6. Triage each comment: fix-and-resolve, push-back-no-resolve, or out-of-scope
    7. If fixes were made: commit, push (HEAD_SHA changes); set PUSHED_SINCE_REQUEST=true
    8. If only push-backs/out-of-scope (no fixes): break — Copilot will keep flagging the same things; report and exit
    9. continue
```

## Step-by-Step

### Step 1: Determine HEAD

```bash
HEAD_SHA=$(git rev-parse HEAD)
```

### Step 2: Re-request Copilot if HEAD changed

```bash
if [ "$LAST_REVIEWED_SHA" != "$HEAD_SHA" ]; then
    gh pr edit "$PR_NUMBER" --add-reviewer @copilot
fi
```

If `--add-reviewer @copilot` is unavailable, fall back to the GraphQL `requestReviews` mutation in `copilot-detection.md`.

### Step 3: Poll for completion

Use the polling cadence in `copilot-detection.md`. Each poll runs the GraphQL review-completion query and checks for a Copilot review whose `commit.oid == HEAD_SHA`.

```bash
# Pseudocode
sleeps=(10 15 30 60 60 60)
elapsed=0
for s in "${sleeps[@]}"; do
    sleep "$s"
    elapsed=$((elapsed + s))
    REVIEW=$(query_copilot_review_for_sha "$HEAD_SHA")
    [ -n "$REVIEW" ] && break
    if [ "$elapsed" -ge 300 ]; then
        ask_user_continue_or_bail
    fi
done
```

### Step 4: Read review comments

The GraphQL response contains a `comments` connection with each comment's:
- `id` (for replies)
- `path`, `line`
- `body` (the comment text)
- `outdated` (whether the line has changed since)
- `pullRequestReviewThread.id` (for thread resolution)

### Step 5: Exit on clean pass

A clean pass means:
- `comments.totalCount == 0`, OR
- All comments are `outdated == true` AND no body issues raised in the review's main body

When clean: jump to **Phase 4: Terminal State** in the SKILL.md.

### Step 6: Triage each comment

For each comment, classify:

| Classification | Trigger | Action |
|----------------|---------|--------|
| **fix-and-resolve** | Real bug, missing edge case, dead code, security issue, clear style violation | Read file at path:line, apply fix, reply `Fixed in <sha-short>. <why>`, resolve thread |
| **push-back** | Copilot misread context, suggestion contradicts CLAUDE.md, suggestion would introduce a bug | Reply with reasoning citing the file/line that justifies, do NOT resolve, append to `unresolved_pushed_back` |
| **out-of-scope** | Suggestion is real but unrelated to this PR's purpose | Reply `Out of scope for this PR. Filing as a follow-up if useful.`, do NOT resolve, append to `unresolved_pushed_back` |
| **already-fixed** | Comment is on outdated code (`outdated: true`) and the fix already happened in a later commit | Reply `Addressed in <sha-short>. The code has changed since this comment.`, resolve thread |

Reply mutation (from review-pr's graphql-queries.md, same shape):

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: $threadId,
    body: $body
  }) { comment { id } }
}' -f threadId="$THREAD_ID" -f body="$REPLY_BODY"
```

Resolve mutation:

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_ID"
```

### Step 7: Commit and push fixes

If at least one comment was classified as **fix-and-resolve**:

```bash
git add <changed-files>
git commit -m "fix: address copilot review (#N)"
git push
```

`HEAD_SHA` will now differ from `LAST_REVIEWED_SHA`. The next iteration's Step 2 will re-request.

### Step 8: All push-backs (no fixes) — terminate

If every comment in this iteration was push-back or out-of-scope (zero fixes applied):
- Stop the loop. Re-requesting Copilot would yield the same comments.
- Report `unresolved_pushed_back` to the user with the loop's reasoning per comment.
- Exit gracefully — let the user decide if Copilot's feedback is right and we're wrong.

## Exit Conditions

| Condition | Outcome |
|-----------|---------|
| Copilot review has 0 actionable comments on current HEAD | **success** |
| All comments triaged as push-back (no fixes applied) | **stalemate** — report and exit |
| Iterations >= MAX_ITERATIONS | **escalate** — ask user to extend |
| 5-min poll budget exceeded with no Copilot review | **escalate** — ask if Copilot is configured for this repo |
| Push rejected non-fast-forward | **escalate** — never force-push |
| Pre-commit hook fails | Fix root cause, retry. Never `--no-verify`. |
| Merge conflicts with base | **escalate** — manual resolution |

## Iteration Budget

- Default `MAX_ITERATIONS = 5`
- User can override at invocation: "copilot loop with 10 iterations"
- After max: report progress (iterations, comments addressed, comments outstanding, head SHA), then ask:
  - Continue +N more iterations
  - Stop and accept Copilot's remaining notes (Copilot is non-blocking)
  - Hand off to human review

## Anti-Loop Safeguards

- **Stalemate detection** (Step 8) prevents infinite re-requests when only push-backs remain.
- **HEAD-SHA tracking** prevents wasted re-requests against an unchanged commit.
- **Per-iteration poll budget** prevents indefinite hangs if Copilot is unavailable.
- **Iteration ceiling** prevents runaway costs (Copilot consumes Actions minutes from June 2026).

## What This Loop Does NOT Do

- **Does not run CI fixes** — that's `review-pr`. If CI failures need addressing alongside Copilot feedback, run `review-pr` after this skill.
- **Does not handle human reviewers** — Copilot only. If a human reviews mid-loop, the loop ignores them; surface their presence at terminal state.
- **Does not auto-merge** — terminal state offers `gh pr merge`; user picks the strategy.
- **Does not force-push** — divergence is a hard stop.
