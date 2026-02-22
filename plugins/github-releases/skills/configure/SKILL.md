---
name: configure
description: Set up GitHub release notes automation by generating .github/release.yml. Use when user says "configure release notes", "set up release categories", "create release.yml", "automate release notes", "customize release notes grouping", or wants to configure how GitHub generates release notes.
---

# Configure

Generates `.github/release.yml` for automated release note categorization.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Always preview** the generated config before writing the file
- **Validate** by generating preview notes after writing the config
- **Respect existing configuration** — if `.github/release.yml` already exists, show it and ask before overwriting
- **Use `--json` flags** for structured output

## Prerequisites Check

```bash
gh auth status
# Check if release.yml already exists
git ls-files .github/release.yml
cat .github/release.yml 2>/dev/null
```

If `.github/release.yml` already exists, show its contents and ask the user whether to update it or create a fresh one.

## Capabilities

### 1. Generate release.yml (Full Workflow)

**Step 1: Analyze repo labels**

```bash
# Get all labels
gh label list --json name,description --limit 200
```

Group labels by category pattern (e.g., `type: *`, `area: *`).

**Step 2: Analyze PR history**

```bash
# Recent PRs with labels
gh pr list --state merged --limit 50 --json title,labels,author
```

Identify which labels are commonly used on PRs.

**Step 3: Generate configuration**

Read `references/release-yml-guide.md` for the full schema and examples.

Map discovered labels to release note categories:
- `type: feature`, `enhancement` → "New Features"
- `type: bug`, `bug`, `fix` → "Bug Fixes"
- `documentation`, `docs` → "Documentation"
- `dependencies`, `dependabot` → "Dependencies"
- `breaking`, `breaking-change` → "Breaking Changes"

**Step 4: Preview config**

Show the complete `.github/release.yml` content to the user. Explain each category and which labels map to it.

**Step 5: Write file**

After user approval, write `.github/release.yml`.

**Step 6: Validate**

```bash
# Generate preview notes using the new config
gh api repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name="HEAD" \
  -f target_commitish="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')" \
  --jq '.body' 2>/dev/null
```

If the preview fails (no previous tags), explain that validation will work once there's a tag.

### 2. Update Existing Configuration

When `.github/release.yml` already exists:

1. Show current config
2. Analyze recent PRs to find labels not covered by existing categories
3. Suggest additions or modifications
4. Preview the updated config
5. Write after approval

### 3. Add Exclusion Patterns

Configure labels or authors to exclude from release notes:

```yaml
changelog:
  exclude:
    labels:
      - "skip-changelog"
      - "internal"
    authors:
      - "dependabot"
      - "renovate"
```

### 4. Suggest Labels

If the repo has few or no labels suitable for release note categorization:

1. Suggest creating labels that map to release note categories
2. Follow the existing label naming convention in the repo
3. Present the full label list to create
4. Create labels after user approval:
   ```bash
   gh label create "type: feature" --color "0e8a16" --description "New feature or enhancement"
   gh label create "type: bug" --color "d73a4a" --description "Something isn't working"
   ```

## Workflow Summary

1. Check for existing `.github/release.yml`
2. Analyze repo labels and PR history
3. Generate categorized configuration
4. Preview with user — **wait for approval**
5. Write `.github/release.yml`
6. Validate by generating preview notes
7. Suggest label improvements if needed

## Troubleshooting

**No labels in repo**:
- Suggest a starter set of labels for release categorization
- The config will still work — uncategorized PRs go to "Other Changes"

**release.yml syntax error**:
- Validate YAML structure. Read `references/release-yml-guide.md` for the correct schema.
- Common mistake: incorrect indentation under `categories`

**Generated notes empty**:
- Need at least one previous tag and one merged PR since that tag
- Check that PRs have labels matching the configured categories

**Permissions**:
- Writing `.github/release.yml` requires write access to the repository
