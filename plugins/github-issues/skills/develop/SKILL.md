---
name: develop
description: Bridge GitHub issues to development workflow — create branches, start work, check status. Use when user says "start working on issue #42", "create a branch for this issue", "develop issue", "check out issue branch", "what's the PR status for this issue", or wants to transition from issue tracking to coding.
---

# Develop

Bridges issue tracking and development workflow. Creates branches, manages work context.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always view the issue first** before starting development
- **Check working tree** for uncommitted changes before switching branches
- **Add a comment** to the issue when starting development
- **Self-assign** the issue when starting work (if not already assigned)

## Prerequisites Check

```bash
gh auth status
git status
```

## Capabilities

### 1. Start Development

Begin work on an issue: view it, create a branch, assign, and comment.

**Workflow**:

1. **View the issue** for context:
   ```bash
   gh issue view NUMBER --json number,title,body,labels,assignees,state
   ```
   Verify the issue is open. If closed, ask the user if they want to reopen it.

2. **Check working tree**:
   ```bash
   git status --porcelain
   ```
   If there are uncommitted changes, warn the user and ask how to proceed (stash, commit, or abort).

3. **Check for existing branches**:
   ```bash
   gh issue develop NUMBER --list 2>/dev/null
   ```
   If a branch already exists, ask the user if they want to check it out instead of creating a new one.

4. **Create and check out the branch**:
   ```bash
   gh issue develop NUMBER --checkout
   ```
   This creates a branch named `NUMBER-slugified-title` and checks it out.

   If `gh issue develop` is not available or fails, fall back to manual creation:
   ```bash
   # Generate branch name: number-slugified-title (max 60 chars)
   git checkout -b "NUMBER-slugified-title"
   ```

5. **Self-assign** (if not already assigned):
   ```bash
   gh issue edit NUMBER --add-assignee @me
   ```

6. **Add development comment**:
   ```bash
   gh issue comment NUMBER --body "Starting development on branch \`BRANCH_NAME\`."
   ```

7. **Present context** — show the user:
   - Issue title and key details
   - Branch name
   - Acceptance criteria (if present in issue body)
   - Related issues to be aware of

### 2. Check Out Existing Issue Branch

Switch to an existing branch linked to an issue.

**Workflow**:

1. **Find linked branches**:
   ```bash
   gh issue develop NUMBER --list 2>/dev/null
   ```

2. **Check working tree** for uncommitted changes

3. **Check out the branch**:
   ```bash
   git checkout BRANCH_NAME
   ```

4. **Show context** — issue details and current branch status

### 3. Show Development Context

Display the development status for an issue.

```bash
# Issue details
gh issue view NUMBER --json number,title,state,body,labels,assignees

# Linked branches
gh issue develop NUMBER --list 2>/dev/null

# Open PRs referencing this issue
gh pr list --search "NUMBER" --json number,title,state,headRefName,statusCheckRollup,reviewDecision

# Related issues
gh issue list --search "keyword" --state all --json number,title,state --limit 10
```

**Present**:
1. **Issue status** — open/closed, assignees, labels
2. **Linked branches** — which branches exist for this issue
3. **Pull requests** — open PRs, their review status, CI status
4. **Related issues** — other issues that may be affected

## Branch Naming

When creating branches manually (fallback):
- Format: `NUMBER-slugified-title`
- Max length: 60 characters
- Slugify: lowercase, replace spaces with hyphens, remove special characters
- Example: issue #42 "Fix login flow for OAuth users" → `42-fix-login-flow-for-oauth-users`

## Troubleshooting

**`gh issue develop` not available**:
- This command requires a recent version of `gh`. Fall back to manual branch creation with `git checkout -b`.

**Branch already exists**:
- Ask the user if they want to check out the existing branch or create a new one with a different name.

**Working tree dirty**:
- Never silently discard changes. Options: stash (`git stash`), commit, or abort the operation.

**Issue is closed**:
- Ask the user if they want to reopen the issue before starting development, or if they want to work on it without reopening.
