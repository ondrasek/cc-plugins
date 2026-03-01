---
type: reference
used_by: triage, manage, refine, develop, organize, create, recommend, review-pr, issue-reviewer
description: Recommended label categories, naming conventions, and color coding for GitHub issue labels.
---

# Label Taxonomy

## Before creating any label

```bash
# Always check existing labels first
gh label list --json name,color,description --limit 100
```

Only create labels when no existing label fits the need. Many repos already have labels that cover common categories.

## Naming Convention

- Lowercase, kebab-case
- **No prefixes** — use plain names like `bug`, not `type: bug`
- NEVER use `type:`, `status:`, `area:`, or any other prefix

## Recommended Labels

### Work type

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | `#d73a4a` | Something isn't working |
| `feature` | `#a2eeef` | New functionality |
| `chore` | `#d4c5f9` | Maintenance, refactoring, dependencies |
| `docs` | `#0075ca` | Documentation only changes |
| `epic` | `#7057ff` | Parent issue tracking a body of work |
| `spike` | `#fbca04` | Research or investigation task |
| `breaking-change` | `#b60205` | Requires migration or changes consumer behavior |

### Area (project-specific)

Area labels are project-specific. Discover them from the codebase:

```bash
# Look at top-level directories for area candidates
ls -d */

# Check existing area labels
gh label list --json name | jq '.[] | select(.name | test("api|auth|ui|db|infra"))'
```

Common patterns:
- `api` — API layer
- `auth` — Authentication/authorization
- `ui` — User interface
- `db` — Database layer
- `infra` — Infrastructure/deployment

### Standard GitHub labels

These are often pre-created by GitHub. Check before creating:
- `good first issue` — Good for newcomers
- `help wanted` — Extra attention is needed
- `duplicate` — This issue already exists
- `wontfix` — This will not be worked on
- `invalid` — Not a valid issue
- `question` — Further information is requested

## Color Coding Convention

Keep the same hue within a category for visual grouping:
- **Work type** — varies by severity/nature (red for bugs, blue for features, purple for chores)
- **Area** — pick a consistent neutral hue (e.g., all grays or all teals)

## Creating a label

```bash
gh label create "LABEL_NAME" --color "HEX_WITHOUT_HASH" --description "Description"

# Examples:
gh label create "bug" --color "d73a4a" --description "Something isn't working"
gh label create "feature" --color "a2eeef" --description "New functionality"
gh label create "api" --color "c5def5" --description "API layer"
```

## What NEVER to create

**Status labels are forbidden.** Do not create any of:
- `triage`, `ready`, `blocked`, `needs-info`, `in-progress`, `review`
- Any label whose purpose is to track workflow state

**Priority labels are forbidden.** Do not create any of:
- `high`, `low`, `medium`, `critical`
- `P0`, `P1`, `P2`, `P3`, `P4`
- `urgent`, `important`
- Any label whose purpose is to rank issue importance

**Prefixed labels are forbidden.** Do not create any of:
- `type: bug`, `status: ready`, `area: api`
- Any label using a `category: value` pattern
