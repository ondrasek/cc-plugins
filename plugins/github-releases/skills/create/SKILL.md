---
name: create
description: Create GitHub releases with intelligent version determination and release notes generation. Use when user says "create a release", "tag a release", "publish a release", "cut a release", "release version X", "new release", "ship it", or wants to create a new GitHub release with proper versioning and notes.
---

# Create

Creates releases with intelligent version suggestion and release notes generation. Drafts by default.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always create as draft by default** — releases trigger webhooks, CI/CD, and notifications; publish only when user explicitly says so
- **Always preview** the full release (tag, title, notes, draft status) and wait for user approval before creating
- **Never create a tag that already exists** — check first with `git tag --list "TAG"`
- **Match the repo's tag naming convention** — detect v-prefix or no-prefix from existing tags
- **Use `--json` flags** for structured output

## Prerequisites Check

```bash
gh auth status
git describe --tags --abbrev=0 2>/dev/null || echo "No tags found"
```

## Capabilities

### 1. Create Release (Full Workflow)

**Step 1: Gather context**

```bash
# Existing tags and naming convention
git tag --sort=-v:refname | head -10

# Latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)

# Commits since last tag (or all commits if no tags)
git log ${LATEST_TAG:+${LATEST_TAG}..}HEAD --oneline --no-merges

# PRs merged since last tag
gh pr list --state merged --search "merged:>LAST_RELEASE_DATE" --json number,title,labels,author --limit 50

# Check for .github/release.yml
git ls-files .github/release.yml

# Default branch
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

**Step 2: Suggest version**

Read `references/version-strategy.md` for detailed version detection logic.

Analyze commits and PRs to suggest version bump:
- Read `references/conventional-commits.md` for commit parsing rules
- Present reasoning: "X breaking changes → MAJOR bump" or "Y new features → MINOR bump" or "Z fixes → PATCH bump"
- If user specifies a version, validate it's higher than the latest tag

**Step 3: Generate release notes**

Read `references/release-notes-templates.md` for note templates.

Three strategies (in priority order):
1. **GitHub auto-generated** — if `.github/release.yml` exists, use `--generate-notes`:
   ```bash
   gh api repos/{owner}/{repo}/releases/generate-notes \
     -f tag_name="TAG" \
     -f target_commitish="BRANCH" \
     -f previous_tag_name="PREV_TAG" \
     --jq '.body'
   ```
2. **PR-based** — group merged PRs by label category (features, fixes, etc.)
3. **Commit-based** — group commits by conventional commit type

**Step 4: Preview release**

Present the complete release to the user:
- Tag name (with convention match confirmation)
- Release title
- Target branch
- Full release notes (formatted)
- Draft status (default: draft)
- Assets to attach (if any)

**Wait for explicit user approval before proceeding.**

**Step 5: Create the release**

```bash
gh release create TAG \
  --title "TITLE" \
  --notes "NOTES" \
  --draft \
  --target BRANCH
```

If the user wants to attach assets:
```bash
gh release create TAG \
  --title "TITLE" \
  --notes "NOTES" \
  --draft \
  --target BRANCH \
  file1.zip file2.tar.gz
```

If the user explicitly requests a published (non-draft) release:
```bash
gh release create TAG \
  --title "TITLE" \
  --notes "NOTES" \
  --target BRANCH
```

**After creation**: Report the release URL.

### 2. Create Pre-release

Same workflow as above, with `--prerelease` flag:

```bash
gh release create TAG \
  --title "TITLE" \
  --notes "NOTES" \
  --draft \
  --prerelease \
  --target BRANCH
```

Pre-release tag convention: append identifier to version (e.g., `v1.2.0-beta.1`, `v1.2.0-rc.1`).

### 3. First Release

When no tags exist, read `references/version-strategy.md` for first-release heuristics.

Special considerations:
- Default to `v0.1.0` for new/experimental projects, `v1.0.0` for stable projects
- Ask the user about stability/maturity
- Generate notes summarizing the project rather than listing commits
- Suggest creating `.github/release.yml` for future releases

## Workflow Summary

1. Gather context (tags, commits, PRs, release.yml)
2. Detect tag convention (v-prefix or not)
3. Suggest version with reasoning
4. Generate release notes (auto, PR-based, or commit-based)
5. Preview complete release — **wait for approval**
6. Create as draft (or published if explicitly requested)
7. Report release URL

## Troubleshooting

**Tag already exists**:
- Check with `git tag --list "TAG"`. If it exists, suggest the next version or ask if the user wants to use a different tag.

**No commits since last tag**:
- Warn that there are no changes to release. Ask if they want to proceed anyway (e.g., re-tag an existing commit).

**Release notes generation fails**:
- Fall back from GitHub auto-generated → PR-based → commit-based
- If all fail, present an empty template for the user to fill in

**Permission denied**:
- Check repo permissions: `gh repo view --json viewerPermission`
- Creating releases requires write access to the repository
