---
type: reference
used_by: create
description: Version detection strategies including semver, CalVer, monorepo tags, and first-release heuristics.
---

# Version Strategy

## Semver Detection from Tags

Analyze existing tags to determine the versioning scheme:

```bash
git tag --sort=-v:refname | head -20
```

### Pattern Recognition

| Tag pattern | Scheme | Next version logic |
|-------------|--------|--------------------|
| `v1.2.3`, `v1.2.2`, `v1.2.1` | Semver with v-prefix | Increment per commit analysis |
| `1.2.3`, `1.2.2` | Semver without v-prefix | Increment per commit analysis |
| `v2024.01.15` | CalVer (date-based) | Use current date |
| `pkg-v1.2.3`, `api-v1.2.3` | Monorepo scoped | Scope to package, increment per analysis |
| `v1.2.3-beta.1` | Semver with prerelease | Increment prerelease or promote to stable |

### Semver Increment Rules

Given current version `MAJOR.MINOR.PATCH`:

- **MAJOR bump** (X+1.0.0):
  - Any `BREAKING CHANGE:` commit or `!:` suffix
  - Breaking API changes mentioned in PR bodies
  - Major dependency upgrades that change behavior

- **MINOR bump** (x.Y+1.0):
  - `feat:` commits or "Add", "New", "Introduce" in PR titles
  - New CLI commands, API endpoints, configuration options
  - Non-breaking additions to public interfaces

- **PATCH bump** (x.y.Z+1):
  - `fix:` commits or "Fix", "Correct", "Resolve" in PR titles
  - `docs:`, `chore:`, `refactor:`, `perf:`, `test:` commits
  - Bug fixes, performance improvements, documentation updates

### When Multiple Bump Types Apply

Take the highest: MAJOR > MINOR > PATCH.

Example: 3 fixes + 1 feature + 1 breaking change = MAJOR bump.

## CalVer Patterns

If tags follow date patterns:

| Format | Example | Usage |
|--------|---------|-------|
| `YYYY.MM.DD` | `2024.01.15` | Daily releases |
| `YYYY.0M` | `2024.01` | Monthly releases |
| `YYYY.MINOR` | `2024.3` | Year + sequential number |

Generate the next CalVer tag using the current date. If a tag for today already exists, append a micro version: `2024.01.15.1`.

## Monorepo Tags

If tags are scoped to packages:

```bash
# List tags for a specific package
git tag --list "package-name-v*" --sort=-v:refname | head 5
```

When creating a release in a monorepo:
1. Ask which package is being released
2. Only analyze commits touching that package's directory
3. Scope the tag with the package prefix

## First Release Heuristics

When no tags exist:

1. **Check for version files**:
   ```bash
   # Python
   grep -r "version" pyproject.toml setup.py setup.cfg 2>/dev/null | head -5
   # Node
   jq '.version' package.json 2>/dev/null
   # Rust
   grep '^version' Cargo.toml 2>/dev/null | head -1
   # .NET
   grep 'Version' *.csproj Directory.Build.props 2>/dev/null | head -5
   ```

2. **Assess project maturity**:
   - Has README with usage docs → more likely stable
   - Has CI/CD pipeline → more likely stable
   - Has tests → more likely stable
   - Commit history < 50 commits → likely early stage

3. **Default suggestions**:
   - Early/experimental project → `v0.1.0`
   - Stable/documented project → `v1.0.0`
   - If a version file already declares `1.x.x` → match that version

4. **Always ask the user** — first release is a significant decision

## Pre-release Versions

Pre-release identifiers follow semver rules:

| Identifier | Usage | Example |
|------------|-------|---------|
| `-alpha.N` | Internal testing, unstable | `v2.0.0-alpha.1` |
| `-beta.N` | External testing, feature-complete | `v2.0.0-beta.3` |
| `-rc.N` | Release candidate, production-ready | `v2.0.0-rc.1` |

**Incrementing pre-releases**:
- `v2.0.0-beta.1` → `v2.0.0-beta.2` (next beta)
- `v2.0.0-beta.3` → `v2.0.0-rc.1` (promote to RC)
- `v2.0.0-rc.2` → `v2.0.0` (promote to stable)
