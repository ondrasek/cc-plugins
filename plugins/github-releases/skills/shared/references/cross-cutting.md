---
type: reference
used_by: create, browse, manage, configure
description: Cross-cutting behaviors that apply to ALL github-releases skills. Read this before executing any skill.
---

# Cross-Cutting Behaviors

Every github-releases skill MUST follow these three behaviors. They are not optional.

## 1. Tag Conventions

**Before creating a tag**, detect and match the repo's existing pattern:

```bash
# Get the last 10 tags to detect naming conventions
git tag --sort=-v:refname | head -10
```

**Convention detection**:
- If existing tags use `v` prefix (e.g., `v1.2.3`): use `v` prefix for new tags
- If existing tags omit `v` prefix (e.g., `1.2.3`): omit `v` prefix
- If no tags exist: default to `v` prefix (e.g., `v0.1.0`)
- If mixed conventions exist: follow the most recent pattern

**Never override the repo's convention** without explicit user instruction.

## 2. Release Context Gathering

**Before any release operation**, gather the current release state:

```bash
# Latest release (may be a prerelease)
gh release list --limit 5 --json tagName,name,isDraft,isPrerelease,publishedAt

# Whether .github/release.yml exists (affects auto-generated notes)
git ls-files .github/release.yml

# Default branch
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Latest tag
git describe --tags --abbrev=0 2>/dev/null
```

**Present context** to the user before suggesting actions:
- Latest release tag and date
- Whether there are draft releases
- Whether `.github/release.yml` exists (enables GitHub's auto-categorized notes)
- Number of commits since last tag

## 3. Semver Awareness

All version suggestions MUST follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0) — breaking changes to public API/behavior
- **MINOR** (x.Y.0) — new features, backward-compatible additions
- **PATCH** (x.y.Z) — bug fixes, documentation, internal changes

**Rules**:
- Never suggest a version bump without explaining the reasoning
- Analyze commits/PRs since last tag to determine bump type
- When unsure, suggest PATCH and explain why
- For pre-1.0 projects: MINOR can include breaking changes (per semver spec)
- Respect pre-release identifiers (e.g., `1.0.0-beta.1`)

**Commit analysis for bump type**:
```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --oneline
```

Look for:
- `BREAKING CHANGE:` or `!:` in commit messages → MAJOR
- `feat:` or new capabilities in PR titles → MINOR
- `fix:`, `docs:`, `chore:`, `refactor:` → PATCH
- If commits are not conventional, analyze PR titles and bodies for intent
