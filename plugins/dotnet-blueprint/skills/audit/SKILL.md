---
name: audit
description: Read-only gap analysis comparing a .NET project's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their project measures up before running setup.
metadata:
  version: 0.1.0
  author: ondrasek
---

# Audit

Read-only — does not modify any files.

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/setup/analysis-checklist.md` — what to check in the target codebase

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1 of `skills/setup/SKILL.md`):
- Detect .NET SDK version, target framework, solution structure
- Inventory existing tool configurations in Directory.Build.props, .editorconfig, .csproj files
- Check for existing hooks in `.claude/settings.json`
- Check for CI pipeline
- Check for analyzer packages

### 2. Compare Against Methodology

For each of the 9 quality dimensions from `methodology.md`, check whether the role is filled:

1. **Testing & Coverage** — Is there a test framework? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is .editorconfig present? Are Roslyn analyzers configured? Is `dotnet format` used?
3. **Type Safety** — Are nullable reference types enabled? What AnalysisLevel? Are nullable warnings treated as errors?
4. **Security Analysis** — Are security analyzers configured? Does NuGet audit run? Framework-specific rules?
5. **Code Complexity** — Are complexity analyzers configured? What thresholds?
6. **Dead Code & Modernization** — Are IDE analyzers configured for dead code? Modern C# idioms enforced?
7. **Documentation** — Is CS1591 (missing XML doc) enforced? For which project types?
8. **Architecture** — Are architecture tests present? Namespace conventions enforced? Dependency hygiene checked?
9. **Version Discipline** — Is there a `<Version>` property? Is the version semver 2.0? Is bump enforcement configured?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event from `methodology.md`:
- SessionStart → NuGet vulnerability audit (non-blocking)
- PostToolUse (Edit|Write) → per-edit auto-fix (formatting)
- Stop → quality gate (all enabled dimensions)
- Stop → auto-commit (optional)
- PostToolUse (Bash) → semver bump enforcement (blocking, only if Dimension 9 active)

### 4. Check CI Coverage

Verify CI pipeline has a job for each enabled dimension:
- test (runner + coverage)
- lint (format check + analyzers)
- build (strict analysis, nullable errors)
- security (NuGet audit + security analyzers)
- version (semver format check)

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Testing & Coverage | Configured | xUnit, coverlet | Coverage at 45%, below 80% recommendation |
| Linting & Formatting | Partial | .editorconfig | Missing StyleCop/Roslynator analyzers |
| Type Safety | Configured | Nullable enabled | AnalysisLevel not set to latest |
| Security Analysis | Missing | — | No security analyzers or NuGet audit |
| Code Complexity | Missing | — | No complexity limits enforced |
| Dead Code | Missing | — | IDE analyzers not configured as warnings |
| Documentation | Missing | — | No XML doc enforcement |
| Architecture | Missing | — | No architecture tests |
| Version Discipline | Missing | — | No version validation configured |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [x] Stop (quality gate)
- [ ] Stop (auto-commit) — not configured
- [ ] SessionStart (dependency hygiene) — not configured

### CI Coverage
- [x] test
- [ ] lint — missing
- [ ] build (strict) — missing
- [ ] security — missing

### Recommendations
1. Run `/dotnet-blueprint:setup` to configure missing dimensions
2. Enable Roslyn analyzer packages for comprehensive analysis
3. Add NuGet vulnerability auditing
4. Consider raising coverage threshold from 45% to 80%
```

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where project-specific thresholds may be appropriate
- Flag outdated analyzer packages that have been superseded
- Report both missing dimensions and misconfigured existing tools

## Troubleshooting

**No .sln file found**:
- Look for .csproj files directly. The project may not use a solution file. Recommend creating one.

**Hooks configured but methodology.md not found**:
- The project may have been configured manually without the plugin. Audit the hooks against the methodology principles anyway.
