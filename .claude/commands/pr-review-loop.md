---
description: Automated PR review loop — triggers Copilot reviews, addresses all feedback, and merges when clean.
argument-hint: Optional PR number, base branch, or "draft" flag
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# PR Review Loop

!`git branch --show-current`
!`git status --short`
!`gh pr view --json number,title,state,url,isDraft,headRefName,baseRefName 2>/dev/null || echo "NO_EXISTING_PR"`

<role>
You are an autonomous PR review loop agent. Your job is to shepherd a pull request through Copilot code review until it is clean, then merge it. You work methodically: trigger a review, wait for it, fix every issue, and repeat until Copilot has no more comments.
</role>

<workflow>

Execute the following phases in order. Each phase completes fully before moving to the next.

## Phase 1 — Ensure a PR exists

<pr_detection>
Use the dynamic context above to determine the current state:

- If `NO_EXISTING_PR` appeared and $ARGUMENTS contains a PR number, use that PR.
- If `NO_EXISTING_PR` appeared and no PR number in $ARGUMENTS, create a new PR:
  1. Determine the base branch (from $ARGUMENTS, or default to `main`).
  2. Push the current branch to origin if not already pushed.
  3. Create the PR using `gh pr create`. If $ARGUMENTS contains "draft", create as draft.
  4. Use a descriptive title derived from the branch name and commit history.
  5. Generate a summary body from `git log <base>...HEAD --oneline`.
- If a PR already exists, use it. Store the PR number for all subsequent operations.

After this phase, confirm the PR number and URL to the user.
</pr_detection>

## Phase 2 — Review loop

<review_loop>
Repeat the following cycle. Exit the loop only when the termination condition is met.

### Step 2.1 — Check for unresolved review comments

First, derive the repository owner and name:

```
gh repo view --json owner,name --jq '.owner.login + "/" + .name'
```

Then query unresolved review threads on the PR, substituting OWNER, REPO, and PR_NUM with the actual values:

```
gh api graphql -f query='{ repository(owner: "OWNER", name: "REPO") { pullRequest(number: PR_NUM) { reviewThreads(first: 100) { nodes { id isResolved comments(first: 3) { nodes { databaseId body path line author { login } } } } } } } }'
```

Count unresolved threads.

### Step 2.2 — Branch on state

<if_unresolved_comments>
If there are unresolved comments, go directly to Step 2.4 (address them).
</if_unresolved_comments>

<if_no_unresolved_comments>
If there are zero unresolved comments, proceed to Step 2.3 (trigger a new review).
</if_no_unresolved_comments>

### Step 2.3 — Trigger Copilot review and wait

1. Request a Copilot review:
   ```
   gh api repos/OWNER/REPO/pulls/PR_NUM/requested_reviewers -f "reviewers[]=copilot-pull-request-reviewer"
   ```
2. Wait for the review to complete. Poll every 30 seconds using:
   ```
   gh api repos/OWNER/REPO/pulls/PR_NUM/reviews --jq '[.[] | select(.user.login=="copilot-pull-request-reviewer")] | sort_by(.submitted_at) | last | .state'
   ```
   The review is complete when the state is non-null (typically `COMMENTED` or `APPROVED`).
   Time out after 10 minutes of polling — if timed out, report and continue to check for comments.
3. After the review lands, go to Step 2.1 to check for new unresolved comments.

### Step 2.4 — Address all review comments

For each unresolved review thread:

1. **Read the comment** — understand what the reviewer is asking for. Note the file path and line number.
2. **Evaluate the comment**:
   - If the comment points to a real issue in the current code, fix it.
   - If the comment is outdated (refers to code that no longer exists or was already fixed), note this in your reply.
   - If the comment is a style preference or suggestion you disagree with, explain your reasoning in the reply.
3. **Fix the code** — read the relevant file, make the necessary edit. Prefer minimal, targeted fixes.
4. **Reply to the comment** on GitHub explaining what you did:
   ```
   gh api repos/OWNER/REPO/pulls/PR_NUM/comments/COMMENT_ID/replies -f body="REPLY"
   ```
5. **Resolve the thread** via GraphQL:
   ```
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "THREAD_ID"}) { thread { isResolved } } }'
   ```

After addressing all comments:

6. **Commit and push** all fixes in a single commit with message: `fix: address copilot review round N feedback` where N is the iteration count.
   - Stage only the files you modified. Do not use `git add -A`.
   - Push to origin.
7. Return to Step 2.1.

### Step 2.5 — Termination condition

<termination_condition>
The loop ends when ALL of these are true:
- A Copilot review was triggered in this iteration (Step 2.3 ran).
- The review completed.
- The review produced zero new unresolved comments.

When the termination condition is met, proceed to Phase 3.
</termination_condition>
</review_loop>

## Phase 3 — Merge the PR

<merge>
1. Verify the PR is in a mergeable state:
   ```
   gh pr view PR_NUM --json mergeable,mergeStateStatus,statusCheckRollup
   ```
2. If the PR is a draft, convert it to ready:
   ```
   gh pr ready PR_NUM
   ```
3. Merge using squash strategy:
   ```
   gh pr merge PR_NUM --squash --delete-branch
   ```
4. Report the final result: PR URL, merge commit, and number of review rounds completed.
</merge>

</workflow>

<guidelines>

- Commit messages for review fixes should follow the pattern: `fix: address copilot review round N feedback` where N is the iteration count.
- When fixing code, read the file first. Never guess at file contents.
- When multiple comments point to the same underlying issue, fix it once and reference the fix in all related replies.
- Batch all fixes for a single review round into one commit.
- Resolve threads only after replying to them.
- If a Copilot comment is about code that was already fixed in a previous round, reply noting it was addressed in a prior commit and resolve the thread.
- Keep replies concise — state what was fixed or why no change was needed.
- If the merge fails due to branch protection or CI, report the failure clearly and stop.
- Track the iteration count and report it at the end.

</guidelines>
