# auto-release

Automated semantic versioning and GitHub releases from conventional commits.

## What It Does

Two things:

1. **PostToolUse hook** — validates that every `git commit` follows the [Conventional Commits](https://www.conventionalcommits.org/) format. Blocks non-conforming commits with exit 2 and instructs Claude to amend.

2. **Setup skill** (`/auto-release:setup`) — installs a GitHub Actions workflow that automatically creates tagged releases when commits are pushed to main. The workflow:
   - Parses conventional commits since the last tag
   - Determines the appropriate semver bump (major/minor/patch)
   - Generates categorized release notes
   - Creates a GitHub release with an annotated tag

## Prerequisites

- **git** — initialized repo with a remote on GitHub
- **gh** CLI — for release creation and status checks
- **jq** — for parsing hook input

## Conventional Commit Format

```
<type>[(scope)][!]: <description>

[body]

[footer]
```

### Type to Version Bump

| Type | Bump | Description |
|------|------|-------------|
| `feat` | MINOR | New feature |
| `fix` | PATCH | Bug fix |
| `docs` | PATCH | Documentation |
| `refactor` | PATCH | Code restructuring |
| `chore` | PATCH | Maintenance |
| `perf` | PATCH | Performance |
| `test` | PATCH | Tests |
| `build` | PATCH | Build system |
| `ci` | PATCH | CI config |
| `style` | PATCH | Formatting |
| `!` suffix | MAJOR | Breaking change |

## Skills

| Skill | Description |
|-------|-------------|
| `/auto-release:setup` | Install release workflow and commit validation in target repo |
| `/auto-release:status` | Preview next release: version bump, release notes, non-conventional commits |

## Installation

```bash
# From the cc-plugins marketplace
/plugin install auto-release@cc-plugins
```

## Local Development

```bash
cd /path/to/your-project
claude --plugin-dir /path/to/cc-plugins/plugins/auto-release
```
