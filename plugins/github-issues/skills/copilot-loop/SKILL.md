---
name: copilot-loop
description: Iterate a feature branch to a clean Copilot review — stage/commit/push, open or update the PR, request a GitHub Copilot code review, wait for the review to land, address each comment with a code fix, push, re-request, and loop until Copilot returns no new comments. Use when user says "copilot review loop", "iterate with copilot", "copilot loop", "merge with copilot", "ship with copilot review", "auto-fix copilot comments", "loop until copilot is happy", or wants automated PR iteration driven by Copilot's feedback.
---

# Copilot Loop

Drives a feature branch from in-progress code to a Copilot-clean PR. One command does:

1. Stage + commit + push pending work on the current branch
2. Find or create the PR with Copilot as a requested reviewer
3. Poll for Copilot's review to land
4. Address each Copilot comment with an actual code fix
5. Push, re-request Copilot, and loop until Copilot's latest review has zero comments
6. Report and offer to merge

This is **distinct from `review-pr`**:
- `review-pr` shepherds a PR through human reviewers + CI checks
- `copilot-loop` drives iteration *purely against Copilot's automated review* and is meant to run repeatedly during active development before asking humans to look

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Never run on `main`/`master`** — refuse and explain
- **Never auto-resolve a Copilot comment** the loop chose not to fix — only resolve threads after a real code change
- **Never auto-merge** — terminal state offers `gh pr merge`, but the user confirms the strategy
- **Never bypass hooks** (`--no-verify`, `--no-gpg-sign`) — if the commit-reference-check hook blocks, fix the message
- **Always include `#N` issue reference** in commit messages when the branch follows the `<number>-<description>` convention (the existing PostToolUse hook enforces this)
- **Max 5 loop iterations by default** — beyond that, ask the user before continuing
- **Copilot reviews are advisory** — Copilot only leaves `COMMENTED` reviews; they never block merging or count toward required approvals
- **Custom-instruction cap** — Copilot reads only the first 4,000 chars of any custom instruction file in the repo
- **Comments back to Copilot are not seen by Copilot** — never try to "talk to" Copilot; the only way to address feedback is to push code and re-request
- **Adding the reviewer ≠ requesting a re-review on every push** — `--add-reviewer @copilot` triggers exactly one review of the current HEAD. Pushing new commits does NOT automatically re-trigger Copilot unless the repo has automatic Copilot review enabled at the repo/org level. The loop MUST explicitly re-request after every push that introduces a new HEAD SHA

## Prerequisites Check

```bash
# 1. Must NOT be on main/master
BRANCH=$(git branch --show-current)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
# If $BRANCH == main/master/$DEFAULT_BRANCH → stop with error

# 2. gh authenticated
gh auth status

# 3. gh version >= 2.88.0 (required for `--reviewer @copilot`)
gh --version

# 4. Inside a git repo with a remote
git remote get-url origin
```

If `gh` is older than 2.88.0, instruct the user to upgrade (`brew upgrade gh` or equivalent) and stop. The `@copilot` reviewer flag is not available on older versions.

## Phase 1: Stage, Commit, Push

### 1a. Inspect the working tree

```bash
git status --porcelain
git diff --stat
git diff --cached --stat
```

If both staged and unstaged buckets are empty AND `git log @{u}..HEAD` (if upstream set) is empty: skip to Phase 2 — there is nothing to push.

### 1b. Stage selectively

- Show the user the changed file list
- Stage by name, not `git add -A` / `git add .` — avoid pulling in `.env`, credentials, build artifacts
- If untracked files look incidental (build output, editor temp files), ask before adding them
- Respect `.gitignore`; never bypass it

```bash
git add <file1> <file2> ...
```

### 1c. Commit

Detect the issue number from the branch name (`<number>-<description>`):

```bash
ISSUE_NUMBER=$(echo "$BRANCH" | grep -oE '^[0-9]+' || true)
```

Compose the commit message:
- Type prefix matches the change (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`)
- One short subject line, present tense, lowercase, no trailing period
- Body only if context is non-obvious (the *why*, not the *what*)
- Trailer with `#N` if `ISSUE_NUMBER` is set (the commit-reference-check hook will block otherwise on issue-linked branches)

```bash
git commit -m "$(cat <<'EOF'
<type>: <subject> (#N)

<optional body explaining why>
EOF
)"
```

If the pre-commit hook fails: fix the underlying issue, re-stage, create a NEW commit. Never `--amend` past a hook failure.

### 1d. Push

```bash
# First push of the branch
git push -u origin HEAD

# Subsequent pushes
git push
```

If the remote rejects with non-fast-forward: stop. Do NOT force-push without explicit user permission. Report the divergence and ask the user how to proceed.

## Phase 2: Ensure PR Exists with Copilot Reviewer

### 2a. Look up existing PR

```bash
gh pr view --json number,url,title,state,baseRefName,isDraft,headRefOid,reviewRequests
```

Decision tree:

| Result | Action |
|--------|--------|
| Exists, OPEN | Go to 2c (re-request Copilot) |
| Exists, DRAFT | Warn that Copilot may not auto-pick up; offer `gh pr ready` |
| Exists, MERGED | Stop: "Already merged." |
| Exists, CLOSED | Ask user: reopen or stop |
| Does not exist | Go to 2b (create) |

### 2b. Create the PR with Copilot as a reviewer

```bash
gh pr create \
  --base "$DEFAULT_BRANCH" \
  --fill \
  --reviewer @copilot
```

If `--reviewer @copilot` is rejected (older gh), create the PR without the flag, capture the new PR number, and use the GraphQL `requestReviews` mutation from 2c to add Copilot.

If `--fill` produces a thin body, propose a richer body covering:
- Summary of what changed (1–3 bullets)
- Linked issue: `Closes #N` (if `ISSUE_NUMBER` is set)
- Test plan (bullet checklist)

Comment on the linked issue:

```bash
[ -n "$ISSUE_NUMBER" ] && gh issue comment "$ISSUE_NUMBER" --body "PR opened: $PR_URL — Copilot review requested."
```

### 2c. Re-request Copilot on existing PR

Primary path (gh ≥ 2.88.0):

```bash
gh pr edit "$PR_NUMBER" --add-reviewer @copilot
```

**Semantics — read carefully:**

- This re-requests a review **of the current HEAD SHA**.
- If Copilot has already reviewed *this exact* HEAD SHA, the request is a no-op (k1LoW's extension confirms this guard exists server-side).
- If Copilot has reviewed an *older* HEAD SHA, the request triggers a fresh review of the new HEAD.
- If Copilot has never been requested, the request triggers the first review.
- **Pushing alone does not trigger Copilot** unless the repo has automatic Copilot review enabled. Always re-request after every push the loop performs.

Fallback path (older gh, or if `--add-reviewer @copilot` fails) — direct GraphQL:

See `references/copilot-detection.md` for the exact `requestReviews` mutation with `botIds`. Briefly:

```bash
# Look up Copilot bot's node ID once (cache it for the session)
COPILOT_BOT_ID=$(gh api graphql -f query='query{user(login:"copilot-pull-request-reviewer"){... on Bot{id}}}' \
  --jq '.data.user.id' 2>/dev/null)

# Look up PR node ID
PR_NODE_ID=$(gh pr view "$PR_NUMBER" --json id --jq '.id')

# Request the review
gh api graphql -f query='
mutation($prId: ID!, $botIds: [ID!]!) {
  requestReviews(input: { pullRequestId: $prId, botIds: $botIds }) {
    pullRequest { id }
  }
}' -f prId="$PR_NODE_ID" -f "botIds[]=$COPILOT_BOT_ID"
```

Track the HEAD SHA each request was made against:

```bash
LAST_REQUESTED_SHA=$(git rev-parse HEAD)
```

Skip re-requesting if `git rev-parse HEAD == LAST_REQUESTED_SHA` AND Copilot's most recent review's `commit.oid` already matches that SHA — that means Copilot already reviewed this exact commit and another request will be a no-op.

## Phase 3: The Loop

Read the detailed spec: `references/loop-workflow.md`.

Each iteration (max 5 by default):

1. **Wait for Copilot's review to appear** (typical latency <30s, see `references/copilot-detection.md`)
2. **Fetch Copilot's latest review and its inline comments** via GraphQL
3. **Evaluate exit conditions**:
   - Latest Copilot review has **zero unresolved inline comments** AND review body is non-blocking → **success**
   - Loop counter ≥ MAX_ITERATIONS → **escalate to user**
4. **For each Copilot comment**: read the file, apply a real code fix, reply with `Fixed in <sha-short>.`, resolve the thread
5. **Commit** the fixes: `fix: address copilot review (#N)`
6. **Push**
7. **Re-request Copilot**: `gh pr edit "$PR_NUMBER" --add-reviewer @copilot`
8. **Continue loop**

### When to fix vs. when to push back

Copilot is opinionated and sometimes wrong. The loop's default disposition is "fix it" because that's what unblocks merging. But:

- **Genuine bug, style, naming, simplification**: fix it, resolve thread.
- **False positive** (Copilot misread context, suggested unsafe change, contradicts CLAUDE.md): reply with reasoning, **do not resolve**, surface to user at terminal state.
- **Out of scope** (Copilot suggests refactor unrelated to the PR): reply "Out of scope for this PR — tracking separately if useful.", do not resolve, surface to user.

Track skipped comments and report them at the end. Comments left unresolved by the loop count against "clean" — the loop will exit on the next iteration and report them, not infinite-loop.

### Polling cadence

- First check: 10s after re-request
- Then: 15s, 30s, 60s, 60s, 60s (cap)
- Total wait budget per iteration: 5 minutes
- After 5 minutes with no Copilot review showing: ask the user whether to keep waiting (Copilot might be skipped if the diff is too small or the repo lacks Copilot access)

## Phase 4: Terminal State

### Success — Copilot is clean

Report:
- PR URL, title, head SHA
- Number of Copilot iterations completed
- Total Copilot comments addressed
- Any comments deliberately not resolved (with the loop's reasoning)

Then offer to merge — ask which strategy:

```bash
gh pr merge "$PR_NUMBER" --squash   # or --merge / --rebase
```

If a linked issue exists:

```bash
gh issue comment "$ISSUE_NUMBER" --body "PR #$PR_NUMBER passed Copilot review after $N iterations. Ready for human review / merge."
```

### Max iterations reached

Report:
- Iterations spent
- Outstanding Copilot comments (path, line, brief)
- Suggest next steps: continue (`+5 more`), stop and merge anyway (Copilot is non-blocking), or hand off to a human review

### No PR could be created / Copilot didn't review

Possible causes:
- Repo doesn't have a Copilot plan with code review enabled → ask user to enable in repo settings
- Branch protection blocks PR creation → report and stop
- gh CLI version < 2.88.0 → upgrade required (caught in prerequisites)

Report the specific cause and stop the loop.

## Examples

### Example 1: Quick happy path

```
User: "copilot review loop"
→ Branch: 42-add-rate-limiter, 3 modified files, no PR yet
→ Stage src/rate_limiter.py, tests/test_rate_limiter.py
→ Commit "feat: add token-bucket rate limiter (#42)"
→ Push -u
→ gh pr create --fill --reviewer @copilot
→ Wait 12s, Copilot review lands with 2 inline comments
→ Comment 1: "magic number 60 — extract constant" → extract WINDOW_SECONDS, reply, resolve
→ Comment 2: "missing test for burst overflow" → add test_burst_overflow, reply, resolve
→ Commit "fix: address copilot review (#42)", push
→ gh pr edit 87 --add-reviewer @copilot
→ Wait 14s, Copilot review lands with 0 comments
→ ✓ Clean. Offer merge.
```

### Example 2: PR exists, Copilot has stale review

```
User: "iterate with copilot"
→ PR #91 exists, last Copilot review at HEAD~3
→ No uncommitted changes; nothing to push in Phase 1
→ Phase 2c: gh pr edit 91 --add-reviewer @copilot
→ Wait, new review lands with 1 comment about thread safety
→ Apply std::sync::Mutex around shared state, reply, resolve
→ Commit, push, re-request
→ Clean → offer merge
```

### Example 3: False positive, surfaced to user

```
User: "loop until copilot is happy"
→ PR #112, Copilot flags "use Vec::with_capacity for performance"
→ But the call site receives a streaming iterator with unknown size — preallocation is wrong here
→ Reply: "Size is unknown at construction (streaming source) — preallocation would mislead readers."
→ Do NOT resolve
→ Re-request Copilot anyway (in case it has other notes)
→ Next review: 0 new comments
→ Report: "Copilot is clean except 1 unresolved comment which we deliberately pushed back on (line 88, perf preallocation). PR is ready for human review."
```

## Troubleshooting

**`gh: unknown flag: --reviewer @copilot`**: gh < 2.88.0. Upgrade.

**Copilot never reviews**: Check `gh pr view --json reviewRequests` — if `@copilot` not present, the request didn't take. Check repo's Copilot code review settings.

**Copilot's review has no inline comments but a body**: That's a clean pass. Treat as success.

**Push rejected non-fast-forward**: Branch diverged. Stop the loop and ask the user — never force-push.

**Pre-commit hook fails**: Fix the issue, re-stage, NEW commit. The loop will pick up the additional commit automatically.

**`commit-reference-check` blocks**: Branch is `<number>-...` but commit lacks `#N`. Add it. The hook output explains exactly what's expected.

**Copilot keeps flagging the same issue we pushed back on**: Expected — Copilot has no memory of replies. Surface it at terminal state and stop iterating on it.
