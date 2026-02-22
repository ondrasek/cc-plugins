---
type: reference
used_by: create
description: Conventional commit format, mapping to version bumps, and fallback strategies for non-conventional repos.
---

# Conventional Commits

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Type → Version Bump Mapping

| Type | Version bump | Description |
|------|-------------|-------------|
| `feat` | MINOR | New feature |
| `fix` | PATCH | Bug fix |
| `docs` | PATCH | Documentation only |
| `style` | PATCH | Formatting, whitespace |
| `refactor` | PATCH | Code change, no feature/fix |
| `perf` | PATCH | Performance improvement |
| `test` | PATCH | Adding/correcting tests |
| `build` | PATCH | Build system changes |
| `ci` | PATCH | CI configuration |
| `chore` | PATCH | Maintenance tasks |
| `revert` | PATCH | Reverts a previous commit |

**Breaking change indicators** (always MAJOR):
- `!` after type/scope: `feat!: remove deprecated API`
- `BREAKING CHANGE:` in footer
- `BREAKING-CHANGE:` in footer

## Parsing Commits

```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --format="%s" --no-merges
```

**Parse each line**:
1. Check for `BREAKING CHANGE` or `!:` → MAJOR
2. Check for `feat:` or `feat(scope):` → MINOR
3. Everything else → PATCH
4. Take the highest bump across all commits

## Fallback: Non-Conventional Repositories

Many repositories do not follow conventional commits. When commits don't follow the convention:

### PR Title Analysis

```bash
gh pr list --state merged --search "merged:>LAST_TAG_DATE" --json title,labels --limit 50
```

**Mapping PR titles to bumps**:

| PR title pattern | Likely bump |
|-----------------|-------------|
| "Add...", "New...", "Introduce...", "Implement..." | MINOR |
| "Fix...", "Correct...", "Resolve...", "Patch..." | PATCH |
| "Remove...", "Delete...", "Drop support..." | Possibly MAJOR — investigate |
| "Update...", "Improve...", "Refactor...", "Clean..." | PATCH |
| "Breaking:", "BREAKING:" | MAJOR |

### Label Analysis

```bash
gh pr list --state merged --search "merged:>LAST_TAG_DATE" --json labels --limit 50
```

**Mapping labels to bumps**:

| Label pattern | Likely bump |
|---------------|-------------|
| `breaking`, `breaking-change`, `major` | MAJOR |
| `feature`, `enhancement`, `minor` | MINOR |
| `bug`, `fix`, `patch`, `documentation`, `chore` | PATCH |

### Commit Message Heuristics

When no conventional commits or PR metadata:
- Count commits → more commits may suggest MINOR over PATCH
- Check for new files → new files often indicate features (MINOR)
- Check for deleted files → deleted files may indicate breaking changes
- Look for migration files → database migrations often indicate MINOR or MAJOR
- Default to PATCH when uncertain and explain the reasoning

## Presenting the Analysis

Always show the user your reasoning:

```
Analyzing 12 commits since v1.3.2:
  - 2 features (feat: add user export, feat: add bulk delete)
  - 5 fixes
  - 3 chores
  - 2 docs updates

Suggested bump: MINOR → v1.4.0
Reason: New features added (user export, bulk delete), no breaking changes detected.
```
