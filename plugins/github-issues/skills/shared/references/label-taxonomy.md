---
type: reference
used_by: triage, manage, refine, develop, organize
description: Recommended label categories, naming conventions, and color coding for GitHub issue labels.
---

# Label Taxonomy

## Before creating any label

```bash
# Always check existing labels first
gh label list --json name,color,description --limit 100
```

Only create labels when no existing label fits the need. Many repos already have labels that cover common categories.

## Recommended Categories

### `type:` — What kind of work

| Label | Color | Description |
|-------|-------|-------------|
| `type: bug` | `#d73a4a` | Something isn't working |
| `type: feature` | `#a2eeef` | New functionality |
| `type: chore` | `#d4c5f9` | Maintenance, refactoring, dependencies |
| `type: docs` | `#0075ca` | Documentation only changes |
| `type: epic` | `#7057ff` | Parent issue tracking a body of work |
| `type: spike` | `#fbca04` | Research or investigation task |
| `type: breaking-change` | `#b60205` | Requires migration or changes consumer behavior |

### `status:` — Current state

| Label | Color | Description |
|-------|-------|-------------|
| `status: triage` | `#e4e669` | Needs initial assessment |
| `status: ready` | `#0e8a16` | Ready for development |
| `status: blocked` | `#b60205` | Cannot proceed, dependency or decision needed |
| `status: needs-info` | `#fbca04` | Waiting for more information from reporter |
| `status: in-progress` | `#1d76db` | Actively being worked on |
| `status: review` | `#5319e7` | Implementation complete, needs review |

### `area:` — Component or domain

Area labels are project-specific. Discover them from the codebase:

```bash
# Look at top-level directories for area candidates
ls -d */

# Check existing area labels
gh label list --json name | jq '.[] | select(.name | startswith("area:"))'
```

Common patterns:
- `area: api` — API layer
- `area: auth` — Authentication/authorization
- `area: ui` — User interface
- `area: db` — Database layer
- `area: infra` — Infrastructure/deployment

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
- **type:** — varies by severity/nature (red for bugs, blue for features, purple for chores)
- **status:** — traffic-light metaphor (green for ready, yellow for waiting, red for blocked)
- **area:** — pick a consistent neutral hue (e.g., all grays or all teals)

## Creating a label

```bash
gh label create "LABEL_NAME" --color "HEX_WITHOUT_HASH" --description "Description"

# Examples:
gh label create "type: bug" --color "d73a4a" --description "Something isn't working"
gh label create "status: ready" --color "0e8a16" --description "Ready for development"
gh label create "area: api" --color "c5def5" --description "API layer"
```

## What NEVER to create

**Priority labels are forbidden.** Do not create any of:
- `priority: high`, `priority: low`, `priority: medium`, `priority: critical`
- `P0`, `P1`, `P2`, `P3`, `P4`
- `urgent`, `important`
- Any label whose purpose is to rank issue importance
