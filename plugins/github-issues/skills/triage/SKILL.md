---
name: triage
description: Query and inspect GitHub issues with natural language. Use when user says "show my issues", "what's assigned to me", "list open bugs", "summarize issue #42", "issue status", "what issues need triage", or wants to browse, search, or get details on GitHub issues.
---

# Triage

Read-only — does not create or modify issues.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always use `--json` flags** for structured data, then present human-readable summaries
- **Surface related issues** when viewing any single issue — search by keywords from title/body
- **Verify `gh` is available** before running any commands

## Prerequisites Check

```bash
gh auth status
```

If this fails, tell the user to run `gh auth login` first.

## Capabilities

### 1. List Issues

Translate natural language queries into `gh issue list` flags.

**Query translation examples**:

| User says | Command |
|-----------|---------|
| "show my issues" | `gh issue list --assignee @me --json number,title,state,labels,updatedAt` |
| "list open bugs" | `gh issue list --label "type: bug" --state open --json number,title,assignees,updatedAt` |
| "what needs triage" | `gh issue list --label "status: triage" --json number,title,createdAt,author` |
| "issues updated this week" | `gh issue list --search "updated:>YYYY-MM-DD" --json number,title,state,updatedAt` |
| "unassigned issues" | `gh issue list --search "no:assignee" --state open --json number,title,labels,createdAt` |
| "issues mentioning auth" | `gh issue list --search "auth" --json number,title,state,labels` |
| "closed issues this month" | `gh issue list --state closed --search "closed:>YYYY-MM-01" --json number,title,closedAt` |

**Common flags**:

```bash
gh issue list \
  --state open|closed|all \
  --assignee @me|USERNAME \
  --label "label-name" \
  --search "QUERY" \
  --limit 30 \
  --json number,title,state,labels,assignees,createdAt,updatedAt,closedAt,author,milestone
```

**Output format**: Present as a readable table or list. Include issue number, title, state, labels, and assignee. Add relative timestamps (e.g., "3 days ago").

### 2. View Issue Detail

Show comprehensive issue information with context.

```bash
# Get full issue data
gh issue view NUMBER --json number,title,state,body,labels,assignees,author,createdAt,updatedAt,closedAt,comments,milestone,projectItems

# Get linked branches and PRs
gh issue develop NUMBER --list 2>/dev/null
```

**Present**:
1. **Header** — number, title, state, author, creation date
2. **Body** — formatted issue description
3. **Labels & milestone** — current labels and milestone
4. **Assignees** — who's working on it
5. **Discussion summary** — summarize comment thread (key points, decisions, open questions)
6. **Linked work** — branches, PRs, referenced issues
7. **Related issues** — search for related issues by keywords from the title/body:
   ```bash
   gh issue list --search "keyword1 keyword2" --state all --json number,title,state --limit 10
   ```
   Present any issues that look related.

### 3. Status Dashboard

Overview of the current issue landscape.

```bash
# Issues assigned to me
gh issue status --json assigned,created,mentioned

# Open issue counts by label
gh issue list --state open --json labels --limit 100
```

**Present**:
- Issues assigned to me (open)
- Issues I created (open)
- Issues mentioning me
- Open issue count by label category (type, status, area)
- Recently updated issues

### 4. Comment on Issues

Add a comment to provide context or ask questions.

```bash
gh issue comment NUMBER --body "Comment text"
```

When the user asks to comment on an issue, compose the comment and confirm with the user before posting.

## Workflow

1. Parse the user's natural language request
2. Translate to appropriate `gh` command with `--json` output
3. Execute and parse the JSON response
4. Present results in a clean, readable format
5. When viewing a single issue, always search for and surface related issues
6. Suggest follow-up actions (e.g., "Want me to assign this?", "Should I add a label?")

## Troubleshooting

**`gh` not found**:
- The GitHub CLI is required. Tell the user to install it: `brew install gh` (macOS) or see https://cli.github.com

**Not in a git repository**:
- Some commands need a repo context. Ask the user to navigate to a repository or specify the repo with `--repo owner/name`.

**No issues found**:
- Check if the search query is too narrow. Suggest broadening the search or trying different keywords.
- Verify the repo has issues enabled: `gh repo view --json hasIssuesEnabled`

**Rate limiting**:
- If API calls fail with rate limit errors, wait and retry. Inform the user about the limitation.
