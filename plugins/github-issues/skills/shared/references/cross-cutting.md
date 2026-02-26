---
type: reference
used_by: triage, manage, refine, develop, organize, create, recommend, issue-reviewer
description: Cross-cutting behaviors that apply to ALL github-issues skills. Read this before executing any skill.
---

# Cross-Cutting Behaviors

Every github-issues skill MUST follow these three behaviors. They are not optional.

## 1. Issue Relationships

**Before creating or editing an issue**, actively search for related issues:

```bash
# Search by keywords from the issue title/body
gh issue list --search "keyword1 keyword2" --json number,title,state --limit 20

# Search across closed issues too
gh issue list --search "keyword" --state all --json number,title,state --limit 10
```

**When referencing related issues**:
- Use `#N` for same-repo references
- Use `owner/repo#N` for cross-repo references
- Add relationship markers in issue bodies:
  - `Related to #N` — loosely connected
  - `See also #N` — useful context
  - `Duplicate of #N` — same issue, close the newer one
  - `Depends on #N` — blocked until that issue resolves
  - `Blocks #N` — that issue is waiting on this one

**When closing an issue**:
- Search for issues that reference it: `gh issue list --search "#N" --state open`
- Add a comment to dependent issues noting the closure

**When creating sub-issues of an epic**:
- Cross-reference siblings: "See also #A, #B, #C (sibling stories under #parent)"

## 2. Comments

Add comments to provide context for changes. Comments explain **why**, not just **what**.

### When to comment

| Action | Comment template |
|--------|-----------------|
| Adding/removing labels | "Added `bug` — this is a defect in existing behavior, not a missing feature." |
| Changing milestone | "Moved to v2.1 milestone — depends on #45 which won't land in v2.0." |
| Closing an issue | "Closing — resolved by #78. The fix covers both the original report and the edge case in #23." |
| Refining an issue | "Refined: added acceptance criteria and user story format. Scope narrowed to X, split Y into #89." |
| Starting development | "Starting development on branch `42-fix-login-flow`. Assigned to myself." |
| Transferring | "Transferring to owner/other-repo — this is closer to their domain." |
| Locking | "Locking conversation — discussion has become unproductive. Decision recorded above." |

### Comment command

```bash
gh issue comment NUMBER --body "Comment text here"
```

## 3. Labels

### Discovery first — ALWAYS

Before creating or suggesting labels, check what exists:

```bash
gh label list --json name,color,description --limit 100
```

### Label naming convention

- Lowercase, kebab-case
- **No prefixes** — use plain names like `bug`, `feature`, `api`
- NEVER use `type:`, `status:`, `area:`, or any other `category: value` pattern

### Creating labels

Only create labels when no existing label fits. Follow the taxonomy in `label-taxonomy.md`.

```bash
gh label create "bug" --color "d73a4a" --description "Something isn't working"
```

### The absolute rules

**NEVER create labels that reflect status.** No `triage`, `ready`, `blocked`, `in-progress`, `needs-info`, `review`, or any workflow-state label.

**NEVER create labels that reflect priority.** No `high`, `low`, `critical`, `P0`, `P1`, etc. This is a firm user requirement with no exceptions.

**NEVER use prefixes in label names.** No `type: bug`, `status: ready`, `area: api`. Use plain names only.

### Suggesting labels

When viewing or creating issues, suggest appropriate existing labels based on:
- Issue title and body content
- Referenced files or components
- Similar issues and their labels
