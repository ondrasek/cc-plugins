---
name: setup
description: Install automated release workflow and commit validation in a repository. Use when user says "set up releases", "add auto-release", "configure CI releases", "install release workflow", or wants automated semantic versioning with conventional commits.
---

# Setup

Installs a GitHub Actions release workflow and conventional commit validation hook in the target repository.

## Critical Rules

- **Read references first**: `skills/setup/references/conventional-commits.md` and `skills/setup/references/workflow-template.md`
- **Never overwrite existing workflows** without confirmation — check for `.github/workflows/release.yml` first
- **Verify prerequisites** before installing anything
- **Present the plan** before making changes — user must approve

## Prerequisites Check

```bash
# Verify tools are available
gh auth status
git rev-parse --is-inside-work-tree
jq --version
```

If any fail, tell the user what to install before proceeding.

## Workflow

### Phase 1: Analyze

Gather information about the target repository:

```bash
# Existing tags and versioning scheme
git tag --sort=-v:refname | head -10

# Current branch
git symbolic-ref --short HEAD

# Existing CI/CD
ls -la .github/workflows/ 2>/dev/null

# Existing hooks configuration
cat .claude/settings.json 2>/dev/null | jq '.hooks // empty'
ls -la hooks/ 2>/dev/null
```

**Determine**:
- Tag prefix convention (default: `v`)
- Initial version if no tags exist (default: `0.1.0`)
- Default branch name (main vs master)
- Whether existing release workflows exist

### Phase 2: Plan

Present findings to the user:

```
Detected:
  - Tag prefix: v (or none found — will use v)
  - Latest tag: v1.2.3 (or none — first release will be v0.1.0)
  - Default branch: main
  - Existing workflows: [list or none]

Will install:
  1. .github/workflows/release.yml — release automation on push to main
  2. .github/release.yml — GitHub auto-generated release note categories
  3. Conventional commit validation hook (PostToolUse on Bash)
```

Wait for user approval before proceeding.

### Phase 3: Install

1. **Create workflow directory**:
   ```bash
   mkdir -p .github/workflows
   ```

2. **Install release workflow** — read `templates/release-workflow.yml` from the plugin directory and customize:
   - Set correct branch name
   - Set tag prefix
   - Set initial version

3. **Install release categories** — create `.github/release.yml` with conventional commit type categories

4. **Register commit validation hook** — add to the project's Claude hooks configuration so conventional commit format is enforced on every `git commit`

### Phase 4: Verify

```bash
# Check files exist
ls -la .github/workflows/release.yml
ls -la .github/release.yml

# Validate YAML syntax (basic check)
head -5 .github/workflows/release.yml

# Verify script permissions
test -x "$(dirname "$0")/../../scripts/validate-conventional-commit.sh" && echo "OK"
```

Report results:
- Files created and their locations
- Hook registration status
- Next steps (push to trigger first release, or create initial tag)

## Troubleshooting

**Workflow already exists**:
- Show diff between existing and new workflow
- Ask user whether to replace, merge, or skip

**No GitHub remote**:
- The release workflow requires GitHub Actions. Verify the repo has a GitHub remote.

**Branch protection rules**:
- If the default branch has protection rules, the workflow may need a PAT instead of GITHUB_TOKEN for tag pushes. Inform the user.

**First release**:
- If no tags exist, suggest creating an initial tag: `git tag -a v0.1.0 -m "Initial release" && git push origin v0.1.0`
