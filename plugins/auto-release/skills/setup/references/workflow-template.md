---
type: reference
used_by: setup
description: Annotated documentation for the GitHub Actions release workflow template.
---

# Release Workflow Template

The template is located at `templates/release-workflow.yml` in the plugin root.

## What It Does

1. **Triggers** on push to the default branch (main)
2. **Finds** the latest git tag
3. **Parses** conventional commits since that tag
4. **Determines** the version bump (major/minor/patch)
5. **Generates** categorized release notes
6. **Creates** an annotated git tag and GitHub release

## Customization Points

When installing the template, adjust these values:

| Variable | Default | Description |
|----------|---------|-------------|
| Branch trigger | `main` | Change to match the repo's default branch |
| `TAG_PREFIX` | `v` | Set to `""` for bare version tags |
| `INITIAL_VERSION` | `0.1.0` | First version if no tags exist |

## Permissions

The workflow needs `contents: write` to:
- Create and push git tags
- Create GitHub releases via `gh release create`

Uses `${{ secrets.GITHUB_TOKEN }}` — no additional secrets needed.

## How Version Detection Works

```
1. git describe --tags --abbrev=0 → latest tag
2. Strip tag prefix → MAJOR.MINOR.PATCH
3. Parse each commit since tag:
   - BREAKING CHANGE or ! → MAJOR
   - feat: → MINOR
   - everything else → PATCH
4. Take highest bump
5. Apply to version numbers
```

## Release Notes Format

Commits are grouped into sections:

```markdown
## Breaking Changes
- feat!: remove deprecated API

## Features
- feat(auth): add OAuth2 login

## Fixes
- fix: correct null pointer

## Other Changes
- docs: update README
- chore(deps): bump lodash
```

Empty sections are omitted.

## Edge Cases

**No previous tags**: Creates first release with `INITIAL_VERSION`.

**No new commits since tag**: Skips release entirely (sets `skip=true`).

**Non-conventional commits**: Placed in "Other Changes" section. Not parsed for bump type — only conventional commits influence the version bump.

**Multiple pushes in quick succession**: GitHub Actions serializes workflow runs on the same branch by default. Later runs will see the tag created by earlier runs.
