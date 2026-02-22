---
type: reference
used_by: setup
description: Conventional commit format specification, type definitions, and version bump mapping rules.
---

# Conventional Commits Reference

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Type Definitions

| Type | Purpose | Version Bump |
|------|---------|-------------|
| `feat` | New feature for the user | MINOR |
| `fix` | Bug fix for the user | PATCH |
| `docs` | Documentation only changes | PATCH |
| `style` | Formatting, whitespace, semicolons | PATCH |
| `refactor` | Code change that neither fixes a bug nor adds a feature | PATCH |
| `perf` | Performance improvement | PATCH |
| `test` | Adding or correcting tests | PATCH |
| `build` | Changes to build system or external dependencies | PATCH |
| `ci` | Changes to CI configuration files and scripts | PATCH |
| `chore` | Other changes that don't modify src or test files | PATCH |
| `revert` | Reverts a previous commit | PATCH |

## Breaking Changes

Any of these indicate a MAJOR version bump:
- `!` after type/scope: `feat!: remove deprecated API`
- `BREAKING CHANGE:` in commit footer
- `BREAKING-CHANGE:` in commit footer

## Scope

Optional, in parentheses after type. Should be a noun describing the section of the codebase:
- `feat(auth): add login endpoint`
- `fix(parser): handle empty input`
- `chore(deps): update lodash`

## Examples

```
feat: add user export functionality

fix(auth): prevent token refresh race condition

docs: update installation instructions

refactor(api)!: restructure endpoint naming

The v1 endpoint paths have been renamed.

BREAKING CHANGE: /api/v1/users is now /api/users
```

## Version Bump Resolution

When multiple commits exist, take the highest bump:

```
MAJOR > MINOR > PATCH

Example: 3 fixes + 1 feature + 1 breaking = MAJOR
Example: 5 fixes + 2 features = MINOR
Example: 3 fixes + 2 chores = PATCH
```
