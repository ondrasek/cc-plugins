---
type: reference
used_by: create
description: Templates for generating release notes — PR-based, commit-based, and first-release formats.
---

# Release Notes Templates

## Strategy Priority

1. **GitHub auto-generated** — use when `.github/release.yml` exists
2. **PR-based** — use when PRs are the primary workflow
3. **Commit-based** — use when PRs are not used or are minimal
4. **First release** — use when no previous releases exist

## 1. GitHub Auto-Generated Notes

When `.github/release.yml` exists, GitHub can generate categorized release notes automatically.

```bash
# Preview auto-generated notes
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name="TAG" \
  -f target_commitish="BRANCH" \
  -f previous_tag_name="PREV_TAG" \
  --jq '.body'
```

Use this output as the base. Review and supplement if needed (e.g., add a summary paragraph at the top).

## 2. PR-Based Notes

Group merged PRs by label category.

```bash
# Get merged PRs since last tag
gh pr list --state merged --search "merged:>PREV_TAG_DATE" \
  --json number,title,labels,author --limit 100
```

### Template

```markdown
## What's Changed

### Breaking Changes
- TITLE (#NUMBER) @AUTHOR

### New Features
- TITLE (#NUMBER) @AUTHOR

### Bug Fixes
- TITLE (#NUMBER) @AUTHOR

### Documentation
- TITLE (#NUMBER) @AUTHOR

### Other Changes
- TITLE (#NUMBER) @AUTHOR

**Full Changelog**: https://github.com/OWNER/REPO/compare/PREV_TAG...NEW_TAG
```

### Label → Category Mapping

| Labels | Category |
|--------|----------|
| `breaking`, `breaking-change` | Breaking Changes |
| `feature`, `enhancement`, `type: feature`, `type: enhancement` | New Features |
| `bug`, `fix`, `type: bug`, `type: fix` | Bug Fixes |
| `documentation`, `docs`, `type: docs` | Documentation |
| `performance`, `perf` | Performance Improvements |
| `security` | Security |
| `dependencies`, `deps`, `dependabot` | Dependencies |
| (unlabeled) | Other Changes |

### Grouping Rules

- Skip empty categories (don't show a "Bug Fixes" heading if there are no bug fixes)
- Within each category, sort by PR number (ascending)
- Include author mention: `@username`
- Include PR link: `(#NUMBER)`
- If a PR has multiple relevant labels, place it in the highest-priority category (Breaking > Features > Fixes > Docs > Other)

## 3. Commit-Based Notes

When PRs are not the primary workflow.

```bash
# Get commits since last tag
git log PREV_TAG..HEAD --format="%h %s (%an)" --no-merges
```

### Template

```markdown
## What's Changed

### Features
- DESCRIPTION (HASH) — AUTHOR

### Bug Fixes
- DESCRIPTION (HASH) — AUTHOR

### Other
- DESCRIPTION (HASH) — AUTHOR

**Full Changelog**: https://github.com/OWNER/REPO/compare/PREV_TAG...NEW_TAG
```

### Conventional Commit → Category Mapping

| Prefix | Category |
|--------|----------|
| `feat:` | Features |
| `fix:` | Bug Fixes |
| `docs:` | Documentation |
| `perf:` | Performance |
| `BREAKING CHANGE` | Breaking Changes |
| Other | Other |

For non-conventional commits, use heuristics from `conventional-commits.md`.

## 4. First Release Notes

When there are no previous releases.

### Template

```markdown
## Initial Release

BRIEF_PROJECT_DESCRIPTION

### Highlights

- KEY_FEATURE_1
- KEY_FEATURE_2
- KEY_FEATURE_3

### Getting Started

BRIEF_SETUP_INSTRUCTIONS_OR_LINK_TO_README
```

### How to populate

1. Read the project's README for description and key features
2. Check for a CHANGELOG file
3. Look at the project structure to identify major components
4. Keep it concise — the README has the full details

## Formatting Rules

- Use GitHub-flavored markdown
- Keep entries to one line each (title + PR/commit reference)
- Don't duplicate the PR body — the link provides the detail
- Always include the "Full Changelog" compare link at the bottom
- If the notes exceed ~50 entries, consider summarizing: "...and N more changes"
