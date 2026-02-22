---
name: status
description: Preview the next release — shows version bump, categorized release notes, and non-conventional commits. Use when user says "release status", "what's next release", "preview release", "release notes", or wants to see what will be in the next version.
---

# Status

Read-only analysis of what the next release will look like.

## Critical Rules

- **Never create tags or releases** — this skill is read-only
- **Always show non-conventional commits** — they won't be categorized properly
- **Use `--no-merges`** to skip merge commits in analysis

## Prerequisites Check

```bash
git rev-parse --is-inside-work-tree
```

## Workflow

### 1. Find Latest Tag

```bash
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
echo "Latest tag: ${LATEST_TAG:-none}"
```

### 2. List Commits Since Tag

```bash
if [ -n "$LATEST_TAG" ]; then
  git log "${LATEST_TAG}..HEAD" --format="%h %s" --no-merges
else
  git log --format="%h %s" --no-merges
fi
```

### 3. Categorize and Analyze

Parse each commit subject against the conventional commit pattern:
`^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.*\))?!?: .+`

**Group commits by type**:
- Breaking Changes (any type with `!` or `BREAKING CHANGE` footer)
- Features (`feat`)
- Fixes (`fix`)
- Other (all other conventional types)
- Non-conventional (commits that don't match the pattern)

### 4. Calculate Version Bump

```
Breaking changes → MAJOR (X+1.0.0)
Features → MINOR (x.Y+1.0)
Everything else → PATCH (x.y.Z+1)

Highest wins: MAJOR > MINOR > PATCH
```

### 5. Present Report

```
Release Status
==============

Latest tag: v1.2.3 (released 2024-01-15)
Commits since tag: 8

Next version: v1.3.0 (MINOR bump — new features detected)

Breaking Changes:
  (none)

Features:
  - abc1234 feat(auth): add OAuth2 login flow
  - def5678 feat(api): add bulk delete endpoint

Fixes:
  - 111aaaa fix: correct null pointer in user lookup
  - 222bbbb fix(ui): resolve dark mode toggle

Other:
  - 333cccc docs: update API reference
  - 444dddd chore(deps): update dependency versions
  - 555eeee refactor(auth): simplify token validation

Non-conventional commits (will not be categorized):
  - 666ffff Update README
  - 777gggg WIP save progress

Preview release notes:
  ## Features
  - feat(auth): add OAuth2 login flow
  - feat(api): add bulk delete endpoint

  ## Fixes
  - fix: correct null pointer in user lookup
  - fix(ui): resolve dark mode toggle

  ## Other Changes
  - docs: update API reference
  - chore(deps): update dependency versions
  - refactor(auth): simplify token validation
```

### 6. Suggest Actions

Based on the analysis, suggest:
- If non-conventional commits exist: "Consider amending these commits to follow conventional format before releasing"
- If no commits since tag: "No changes to release"
- If ready: "Push to main to trigger automatic release"

## Troubleshooting

**No tags found**:
- Show all commits and suggest creating an initial tag
- Default first release would be `v0.1.0`

**Very large number of commits**:
- Limit to last 100 commits with `--limit 100`
- Warn that older commits are not shown
