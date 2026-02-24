---
name: manage
description: Edit, close, reopen, delete, and manage GitHub issues and labels. Use when user says "close issue #42", "update the title", "add labels", "assign to", "reopen", "delete issue", "manage labels", or wants to modify existing GitHub issues. For creating new issues, use the create skill instead.
---

# Manage

Modifies existing issues — edit, close, reopen, delete, batch operations, and label management.

For creating new issues, use `/github-issues:create`.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always add a comment** when making significant changes (labels, milestone, assignee)
- **Always preview** before making major edits
- **NEVER create priority labels** — see `skills/shared/references/label-taxonomy.md`
- **Use `--json` flags** for structured output

## Prerequisites Check

```bash
gh auth status
```

## Review Before Modifying

Before executing any issue edit (title, body, labels, assignee, milestone), delegate to the `issue-reviewer` agent to validate the proposed changes. Present the review results to the user. If the review fails, fix the issues before proceeding.

## Capabilities

### 1. Edit Issue

Modify issue properties with context.

```bash
# Edit title
gh issue edit NUMBER --title "New title"

# Edit body
gh issue edit NUMBER --body "New body"

# Add labels
gh issue edit NUMBER --add-label "bug"

# Remove labels
gh issue edit NUMBER --remove-label "chore"

# Set assignee
gh issue edit NUMBER --add-assignee USERNAME

# Remove assignee
gh issue edit NUMBER --remove-assignee USERNAME

# Set milestone
gh issue edit NUMBER --milestone "v2.0"
```

**Always add a comment explaining the change**:
```bash
gh issue comment NUMBER --body "Updated labels: added \`bug\` — this is a defect in existing behavior, not a missing feature."
```

### 3. Close Issue

**Workflow**:

1. **View the issue** — understand what's being closed
2. **Check for dependents** — search for issues referencing this one:
   ```bash
   gh issue list --search "#NUMBER" --state open --json number,title
   ```
3. **Close with reason**:
   ```bash
   # Completed
   gh issue close NUMBER --reason completed --comment "Resolved by #PR or description of resolution"

   # Not planned
   gh issue close NUMBER --reason "not planned" --comment "Reason for not proceeding"
   ```
4. **Notify dependents** — if other issues reference this one, comment on them:
   ```bash
   gh issue comment DEPENDENT_NUMBER --body "Note: #NUMBER has been closed. Impact on this issue: ..."
   ```

### 4. Reopen Issue

```bash
gh issue reopen NUMBER --comment "Reopening — the fix in #PR did not fully resolve the problem. See reproduction steps: ..."
```

### 5. Delete Issue

**Use with extreme caution.** Deletion is irreversible.

```bash
# Always warn the user first
gh issue delete NUMBER --yes
```

Only proceed after explicit user confirmation. Suggest closing instead of deleting in most cases.

### 6. Batch Operations

For operations across multiple issues, read `references/batch-operations.md` for safety rules and patterns.

**Common batch operations**:
- Apply a label to multiple issues
- Close multiple resolved issues
- Assign a set of issues to someone

### 7. Label Management

**List existing labels**:
```bash
gh label list --json name,color,description --limit 100
```

**Create a label** (following taxonomy in `skills/shared/references/label-taxonomy.md`):
```bash
gh label create "LABEL_NAME" --color "HEX" --description "Description"
```

**Edit a label**:
```bash
gh label edit "OLD_NAME" --name "NEW_NAME" --color "HEX" --description "Description"
```

**Delete a label**:
```bash
gh label delete "LABEL_NAME" --yes
```

**Rules**:
- Always check existing labels before creating
- Follow the naming convention: lowercase, kebab-case, no prefixes
- **NEVER create priority labels** — this is an absolute rule
- **NEVER create status labels** — no workflow-state labels
- **NEVER use prefixes** — no `type:`, `status:`, `area:` patterns

## Troubleshooting

**Issue creation fails**:
- Verify the repo has issues enabled: `gh repo view --json hasIssuesEnabled`
- Check that labels exist before referencing them in create

**Permission denied on edit**:
- The user may not have write access to the repo. Check with `gh repo view --json viewerPermission`

**Milestone not found**:
- List available milestones: `gh api repos/{owner}/{repo}/milestones --jq '.[].title'`
