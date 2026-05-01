---
type: reference
used_by: copilot-loop
description: Identifying the Copilot reviewer bot, requesting a review via gh CLI or GraphQL, and detecting when a review has landed on the current HEAD SHA.
---

# Copilot Detection and Review Requesting

## The Copilot Bot Identity

The reviewer GitHub publishes for Copilot code review is a `Bot` (not a User):

| Field | Value |
|-------|-------|
| Login | `copilot-pull-request-reviewer[bot]` (with `[bot]` suffix in payload) |
| Login as a string for `gh pr edit --add-reviewer` | `@copilot` |
| Numeric (database) ID | `175728472` |
| Node ID prefix | `BOT_kgDO...` (opaque, fetch at runtime) |

The numeric ID is stable but not guaranteed by GitHub — always look up the node ID at runtime if you need it for GraphQL.

### Looking up the bot's node ID

```bash
gh api graphql -f query='
query {
  user(login: "copilot-pull-request-reviewer") {
    ... on Bot { id databaseId login }
  }
}' --jq '.data.user.id'
```

If the `user` query fails for the bot, fall back to fetching it from a known-good PR's `requestedReviewers`:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewRequests(first: 20) {
        nodes {
          requestedReviewer {
            __typename
            ... on Bot { id login }
            ... on User { id login }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$PR_NUMBER" \
  --jq '.data.repository.pullRequest.reviewRequests.nodes[] | select(.requestedReviewer.__typename == "Bot") | .requestedReviewer.id'
```

## Requesting a Review

### Primary: gh CLI flag (gh ≥ 2.88.0)

```bash
# On an existing PR
gh pr edit "$PR_NUMBER" --add-reviewer @copilot

# When creating a new PR
gh pr create --reviewer @copilot --fill
```

This is the path GitHub officially announced in the [March 2026 changelog](https://github.blog/changelog/2026-03-11-request-copilot-code-review-from-github-cli/).

### Fallback: GraphQL `requestReviews` mutation

The mutation accepts a special `botIds` field that isn't exposed via the REST `requested_reviewers` endpoint — that REST endpoint only takes `users` and `team_reviewers`, which is why earlier "you can't add Copilot via API" advice circulated. The GraphQL mutation works:

```bash
PR_NODE_ID=$(gh pr view "$PR_NUMBER" --json id --jq '.id')
COPILOT_BOT_ID=$(gh api graphql -f query='
  query { user(login: "copilot-pull-request-reviewer") { ... on Bot { id } } }
' --jq '.data.user.id')

gh api graphql -f query='
mutation($prId: ID!, $botIds: [ID!]!) {
  requestReviews(input: {
    pullRequestId: $prId,
    botIds: $botIds,
    union: true
  }) {
    pullRequest {
      id
      reviewRequests(first: 20) {
        nodes { requestedReviewer { __typename ... on Bot { login } } }
      }
    }
  }
}' -f prId="$PR_NODE_ID" -f "botIds[]=$COPILOT_BOT_ID"
```

`union: true` keeps existing requested reviewers; without it, the mutation replaces them.

## Adding-Reviewer vs. Requesting-Re-Review

These are NOT the same thing:

| Action | Effect |
|--------|--------|
| Adding `@copilot` as a reviewer the first time | Copilot reviews the current HEAD once |
| Pushing a new commit to the PR | **Does NOT** trigger a new review (unless repo has automatic Copilot review enabled) |
| Re-running `--add-reviewer @copilot` after pushing a new HEAD | Copilot re-reviews the new HEAD SHA |
| Re-running `--add-reviewer @copilot` *without* a new HEAD | No-op — Copilot has already reviewed this SHA |

The loop must explicitly re-request after every push, and should track the HEAD SHA the last request was made against to detect no-op situations.

### Detecting auto-review

If the repo has automatic Copilot review configured, Copilot reviews each push regardless. Detection isn't fully exposed via gh, but:

```bash
# Heuristic: list reviews and see if Copilot's reviews map 1:1 to commits
gh pr view "$PR_NUMBER" --json reviews --jq \
  '.reviews[] | select(.author.login == "copilot-pull-request-reviewer" or .author.login == "Copilot")'
```

If multiple Copilot reviews exist across multiple commit SHAs without explicit `--add-reviewer` calls, auto-review is on. In that case, the loop can skip the re-request step but must still poll for the new review.

## Detecting Review Completion

A Copilot review is "done" when a PullRequestReview exists whose:
- `author.login` matches `copilot-pull-request-reviewer` (or `Copilot`)
- `commit.oid` matches the current HEAD SHA
- `state` is `COMMENTED` (Copilot never APPROVES or REQUESTS_CHANGES)

```bash
HEAD_SHA=$(git rev-parse HEAD)
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviews(last: 20) {
        nodes {
          id
          state
          submittedAt
          author { login }
          commit { oid }
          body
          comments(first: 100) {
            totalCount
            nodes {
              id
              path
              line
              body
              outdated
              pullRequestReviewThread { id isResolved }
            }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$PR_NUMBER" \
  --jq --arg sha "$HEAD_SHA" '
    .data.repository.pullRequest.reviews.nodes[]
    | select((.author.login | ascii_downcase | contains("copilot")) and .commit.oid == $sha)
  '
```

If this returns an object: Copilot's review of the current HEAD has landed. Inspect `comments.totalCount`:

- `0` and review body is empty or "no issues" → **clean pass**
- `> 0` → comments to address

If it returns nothing: Copilot hasn't reviewed this HEAD yet. Wait per the polling cadence in `loop-workflow.md`.

## Polling Cadence

Copilot reviews typically land in <30s. Recommended schedule per re-request:

| Wait # | Sleep before next poll |
|--------|------------------------|
| 1 | 10s |
| 2 | 15s |
| 3 | 30s |
| 4 | 60s |
| 5+ | 60s |

Per-iteration budget: **5 minutes** of total polling. After that, ask the user whether to keep waiting (Copilot may be skipped on tiny diffs, or the repo lacks the Copilot plan).

## Marking Previous Reviews as Outdated (Optional)

Once new commits supersede earlier Copilot comments, the threads naturally show `isOutdated: true`. The loop does not need to manipulate this — when a new review lands, focus on its fresh comments and treat the old, outdated threads as resolved-by-supersession. Only minimize/resolve them if the user asks for explicit cleanup.
