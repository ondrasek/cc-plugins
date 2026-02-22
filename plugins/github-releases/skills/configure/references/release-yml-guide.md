---
type: reference
used_by: configure
description: Complete .github/release.yml schema, category ordering, exclude patterns, and examples.
---

# .github/release.yml Guide

## Schema

```yaml
changelog:
  exclude:
    labels:
      - LABEL_NAME
    authors:
      - USERNAME
  categories:
    - title: CATEGORY_TITLE
      labels:
        - LABEL_NAME
    - title: CATEGORY_TITLE
      labels:
        - "*"          # Catch-all for unlabeled PRs
```

## Field Reference

### `changelog.exclude`

PRs matching these criteria are omitted from generated notes entirely.

| Field | Type | Description |
|-------|------|-------------|
| `labels` | list of strings | PRs with any of these labels are excluded |
| `authors` | list of strings | PRs by these authors are excluded |

### `changelog.categories`

Ordered list of categories. Each merged PR is placed in the **first matching category**.

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Section heading in release notes |
| `labels` | list of strings | PRs with any of these labels go in this category |

**Special label `"*"`**: Matches any PR, including unlabeled ones. Use as a catch-all in the last category.

## Category Ordering

Categories are evaluated top-to-bottom. A PR goes into the **first** category whose labels match. This means:

1. Put high-priority categories first (Breaking Changes)
2. Put specific categories before general ones
3. Put the catch-all (`"*"`) last

## Recommended Configuration

### Standard Project

```yaml
changelog:
  exclude:
    labels:
      - "skip-changelog"
    authors:
      - "dependabot"
      - "renovate"
  categories:
    - title: "Breaking Changes"
      labels:
        - "breaking"
        - "breaking-change"
    - title: "New Features"
      labels:
        - "feature"
        - "enhancement"
        - "type: feature"
        - "type: enhancement"
    - title: "Bug Fixes"
      labels:
        - "bug"
        - "fix"
        - "type: bug"
        - "type: fix"
    - title: "Performance"
      labels:
        - "performance"
        - "perf"
    - title: "Documentation"
      labels:
        - "documentation"
        - "docs"
        - "type: docs"
    - title: "Dependencies"
      labels:
        - "dependencies"
        - "deps"
    - title: "Other Changes"
      labels:
        - "*"
```

### Minimal Project

```yaml
changelog:
  categories:
    - title: "New Features"
      labels:
        - "enhancement"
    - title: "Bug Fixes"
      labels:
        - "bug"
    - title: "Other Changes"
      labels:
        - "*"
```

### Monorepo

```yaml
changelog:
  exclude:
    labels:
      - "skip-changelog"
  categories:
    - title: "Breaking Changes"
      labels:
        - "breaking"
    - title: "Frontend"
      labels:
        - "area: frontend"
    - title: "Backend"
      labels:
        - "area: backend"
    - title: "Infrastructure"
      labels:
        - "area: infra"
        - "ci/cd"
    - title: "Other Changes"
      labels:
        - "*"
```

## Common Exclude Patterns

### Bot Authors

```yaml
exclude:
  authors:
    - "dependabot"
    - "dependabot[bot]"
    - "renovate"
    - "renovate[bot]"
    - "github-actions[bot]"
```

### Internal/Skip Labels

```yaml
exclude:
  labels:
    - "skip-changelog"
    - "internal"
    - "no-release-note"
    - "wontfix"
    - "duplicate"
    - "invalid"
```

## Adapting to Existing Labels

When generating the config, match categories to the labels that actually exist in the repo:

1. Get all labels: `gh label list --json name --limit 200`
2. For each standard category, check if matching labels exist
3. Only include labels that exist — don't reference non-existent labels
4. If no labels match a category, omit that category
5. Always include a `"*"` catch-all as the last category

## Validation

After writing `.github/release.yml`, verify it works:

```bash
# Generate preview notes (needs at least one tag)
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name="HEAD" \
  -f target_commitish="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')" \
  --jq '.body'
```

If this returns categorized notes, the config is working.
