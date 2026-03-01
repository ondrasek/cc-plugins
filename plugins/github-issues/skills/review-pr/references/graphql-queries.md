---
type: reference
used_by: review-pr
description: GraphQL queries and mutations for PR review threads — fetch unresolved threads, reply, and resolve.
---

# GraphQL Queries for Review Threads

The REST API does not expose `isResolved` on review threads. All thread operations use GitHub's GraphQL API via `gh api graphql`.

## 1. Fetch Unresolved Review Threads

Returns all review threads on a PR with their resolution status, file path, line, and comments.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes {
              body
              author { login }
              createdAt
            }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$PR_NUMBER"
```

### Extracting owner/repo/number

```bash
# From current PR
OWNER=$(gh repo view --json owner -q '.owner.login')
REPO=$(gh repo view --json name -q '.name')
PR_NUMBER=$(gh pr view --json number -q '.number')
```

### Filtering unresolved threads with jq

```bash
# Pipe the GraphQL output to extract only unresolved threads
... | jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

### Response shape

Each thread node contains:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `ID` | Thread ID — used in reply and resolve mutations |
| `isResolved` | `Boolean` | Whether the thread has been resolved |
| `isOutdated` | `Boolean` | Whether the thread's code context is outdated (file changed since comment) |
| `path` | `String` | File path the comment is attached to |
| `line` | `Int` | Line number in the diff |
| `comments.nodes[]` | `Array` | Comments in the thread, each with `body`, `author.login`, `createdAt` |

## 2. Reply to a Review Thread

Adds a reply to an existing review thread. Use this to explain what was fixed or to respond to reviewer feedback.

```bash
gh api graphql -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: $threadId,
    body: $body
  }) {
    comment { id }
  }
}' -f threadId="$THREAD_ID" -f body="$REPLY_BODY"
```

### Common reply patterns

- **Code fix**: `"Fixed in <sha-short>. <brief explanation of what changed>."`
- **Clarification**: `"Good point — <explanation>. I've updated the code to <what changed>."`
- **Disagreement**: `"I considered that, but <reasoning>. Happy to discuss further."` (Do NOT resolve — leave for reviewer.)

## 3. Resolve a Review Thread

Marks a thread as resolved. **Only use after making a code fix** — never resolve threads that are open questions or disagreements.

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_ID"
```

## 4. Unresolve a Review Thread

Re-opens a previously resolved thread. Rarely needed but available if a fix was incorrect.

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  unresolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}' -f threadId="$THREAD_ID"
```

## Important Notes

- **Thread ID format**: GraphQL IDs are opaque strings (e.g., `PRRT_kwDOABC...`). Always use the `id` field from the fetch query.
- **Rate limits**: GraphQL has a separate rate limit (5,000 points/hour). Each query above costs 1 point. Not a concern for typical PR workflows.
- **Permissions**: Requires `repo` scope. The same `gh auth` that works for REST works for GraphQL.
- **`isOutdated` threads**: These are threads where the code has changed since the comment was made. They may still be unresolved — address them if the feedback is still relevant.
