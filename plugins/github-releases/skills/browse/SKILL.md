---
name: browse
description: List, view, and compare GitHub releases with natural language. Use when user says "show releases", "latest release", "what changed in v2.0", "release history", "compare releases", "show stable releases", "list drafts", or wants to browse, search, or inspect releases.
---

# Browse

Read-only — does not create or modify releases.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always use `--json` flags** for structured data, then present human-readable summaries
- **Verify `gh` is available** before running any commands

## Prerequisites Check

```bash
gh auth status
```

If this fails, tell the user to run `gh auth login` first.

## Capabilities

### 1. List Releases

Translate natural language queries into `gh release list` flags.

**Query translation examples**:

| User says | Command |
|-----------|---------|
| "show releases" | `gh release list --limit 10 --json tagName,name,isDraft,isPrerelease,publishedAt` |
| "latest release" | `gh release view --json tagName,name,body,publishedAt,assets` |
| "show stable releases" | `gh release list --exclude-drafts --exclude-pre-releases --json tagName,name,publishedAt` |
| "list drafts" | `gh release list --json tagName,name,isDraft,publishedAt` then filter `isDraft=true` |
| "releases this year" | `gh release list --limit 50 --json tagName,publishedAt` then filter by date |

**Common flags**:

```bash
gh release list \
  --limit 30 \
  --exclude-drafts \
  --exclude-pre-releases \
  --json tagName,name,isDraft,isPrerelease,publishedAt,isLatest
```

**Output format**: Present as a readable table. Include tag, title, date, and status indicators (draft, prerelease, latest). Add relative timestamps (e.g., "3 weeks ago").

### 2. View Release Detail

Show comprehensive release information.

```bash
# Get full release data
gh release view TAG --json tagName,name,body,publishedAt,isDraft,isPrerelease,assets,author,targetCommitish

# Get assets with download counts (if available)
gh release view TAG --json assets
```

**Present**:
1. **Header** — tag, title, author, publish date, status (draft/prerelease/latest)
2. **Release notes** — formatted body content
3. **Assets** — file names and sizes
4. **Target** — branch or commit the release was created from

### 3. Compare Releases

Show what changed between two releases.

```bash
# Commits between two tags
git log TAG1..TAG2 --oneline --no-merges

# PRs merged between tags
gh pr list --search "merged:>DATE1 merged:<DATE2" --state merged --json number,title,labels,author --limit 50

# Full diff stats
git diff --stat TAG1..TAG2
```

**Present**:
- Number of commits between releases
- Notable PRs merged (grouped by label category if possible)
- Files changed summary (insertions/deletions)

### 4. Unreleased Changes

Show what has changed since the last release.

```bash
# Latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)

# Commits since last tag
git log ${LATEST_TAG}..HEAD --oneline --no-merges

# PR count since last tag
gh pr list --search "merged:>LATEST_TAG_DATE" --state merged --json number,title --limit 50
```

**Present**:
- Commits since last release (count and summary)
- PRs merged since last release
- Suggested next version based on change analysis

## Workflow

1. Parse the user's natural language request
2. Translate to appropriate `gh release` or `git` command
3. Execute and parse the response
4. Present results in a clean, readable format
5. Suggest follow-up actions (e.g., "Want me to create a release?", "Should I compare with the previous version?")

## Troubleshooting

**`gh` not found**:
- The GitHub CLI is required. Tell the user to install it: `brew install gh` (macOS) or see https://cli.github.com

**Not in a git repository**:
- Release commands need a repo context. Ask the user to navigate to a repository or specify the repo with `--repo owner/name`.

**No releases found**:
- Check if the repo has any tags: `git tag --list`
- The repo may not have published any releases yet. Suggest creating one.

**Rate limiting**:
- If API calls fail with rate limit errors, wait and retry. Inform the user about the limitation.
