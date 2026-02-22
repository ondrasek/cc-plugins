---
name: manage
description: Edit, publish, delete, and manage GitHub releases and their assets. Use when user says "edit release notes", "publish the draft", "delete release", "upload asset", "download release assets", "update release title", or wants to modify existing releases.
---

# Manage

Modifies existing releases. Preview-before-execute for all operations.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always preview** changes and wait for user approval before modifying
- **Warn before destructive actions** — deleting a release or asset is irreversible
- **Match tag conventions** — don't change tag naming patterns when editing
- **Use `--json` flags** for structured output

## Prerequisites Check

```bash
gh auth status
```

## Capabilities

### 1. Edit Release

Modify release title, notes, or metadata.

```bash
# View current release state
gh release view TAG --json tagName,name,body,isDraft,isPrerelease,targetCommitish

# Edit title
gh release edit TAG --title "New Title"

# Edit notes
gh release edit TAG --notes "New release notes content"

# Edit notes from file
gh release edit TAG --notes-file CHANGELOG.md

# Change draft status (publish)
gh release edit TAG --draft=false

# Change prerelease status
gh release edit TAG --prerelease

# Remove prerelease flag
gh release edit TAG --prerelease=false

# Change target
gh release edit TAG --target BRANCH
```

**Workflow**:
1. Fetch current release details
2. Show current state to user
3. Apply requested changes — preview diff if editing notes
4. Wait for user approval
5. Execute edit
6. Confirm changes applied

### 2. Publish Draft

Transition a draft release to published.

```bash
# List drafts
gh release list --json tagName,name,isDraft | jq '[.[] | select(.isDraft)]'

# Preview draft content
gh release view TAG --json tagName,name,body,assets

# Publish
gh release edit TAG --draft=false
```

**Always warn**: Publishing triggers webhooks, notifications, and may trigger CI/CD workflows. Confirm with user before publishing.

### 3. Delete Release

**Use with extreme caution.** Deletion is irreversible.

```bash
# Show what will be deleted
gh release view TAG --json tagName,name,body,assets

# Delete release (keeps the git tag)
gh release delete TAG --yes

# Delete release AND the git tag
gh release delete TAG --yes --cleanup-tag
```

**Workflow**:
1. Show full release details including assets
2. Warn that deletion is permanent
3. Ask if they also want to delete the git tag
4. Only proceed after explicit user confirmation
5. Suggest alternative: convert to draft instead of deleting

### 4. Manage Assets

Read `references/asset-management.md` for asset naming patterns and best practices.

**Upload assets**:
```bash
# Upload files to an existing release
gh release upload TAG file1.zip file2.tar.gz

# Overwrite existing assets
gh release upload TAG file.zip --clobber
```

**Download assets**:
```bash
# Download all assets
gh release download TAG

# Download to specific directory
gh release download TAG --dir ./downloads

# Download specific asset by pattern
gh release download TAG --pattern "*.tar.gz"
```

**List assets**:
```bash
gh release view TAG --json assets --jq '.assets[] | "\(.name) (\(.size) bytes)"'
```

**Delete asset**:
```bash
# List assets to find the one to delete
gh release view TAG --json assets --jq '.assets[] | "\(.name) - \(.url)"'

# Delete via API (gh release doesn't have delete-asset directly)
gh api -X DELETE repos/{owner}/{repo}/releases/assets/{asset_id}
```

### 5. Promote Pre-release to Stable

```bash
# Remove prerelease flag
gh release edit TAG --prerelease=false

# Optionally update title
gh release edit TAG --title "v1.2.0" --prerelease=false
```

### 6. Convert Published to Draft

```bash
gh release edit TAG --draft
```

**Warn**: This will remove the release from the public releases page, but won't undo any webhook/CI triggers that already fired.

## Troubleshooting

**Release not found**:
- Verify the tag exists: `gh release view TAG 2>&1`
- List available releases: `gh release list --limit 20`
- Tags are case-sensitive

**Permission denied**:
- Check repo permissions: `gh repo view --json viewerPermission`
- Release management requires write access

**Asset upload fails**:
- Check file exists and is readable
- Asset names must be unique within a release (use `--clobber` to overwrite)
- GitHub has a 2 GB per-file limit for release assets
