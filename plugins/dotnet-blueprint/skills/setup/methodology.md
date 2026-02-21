# .NET Quality Methodology

This document defines the quality methodology applied by the `dotnet-blueprint` plugin. It is organized into 8 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem and .NET version.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**Role**: Verify that code changes are backed by tests. Measure and enforce test coverage thresholds.

**What the tool must do**:
- Discover and run test projects
- Stop on first failure (fail-fast mode)
- Measure line coverage against a threshold
- Report uncovered lines

**Default thresholds**:
- Minimum coverage: 90%
- Test directory: `tests/`

**Adaptation**:
- New project (< 500 LOC): 70%
- Legacy project adopting methodology: start at current coverage, increase incrementally

**Quality gate**: Run tests (fail-fast), then run coverage check against threshold.

**CI job**: `test` — run tests with coverage, upload report on PRs.

---

## Dimension 2: Linting & Formatting

**Role**: Enforce consistent code style. Auto-detect and fix common bugs, anti-patterns, and naming conventions. Enforce .editorconfig rules.

**What the tools must do**:
- Lint: enforce Roslyn analyzer rules via .editorconfig (naming, style, usage patterns)
- Format: enforce consistent whitespace, indentation, newlines via `dotnet format`
- Analyzer packages: catch common bugs, anti-patterns, and framework misuse

**Default configuration**:
- .editorconfig with C# conventions (AllmanBraces, PascalCase types, camelCase locals)
- `dotnet format` on every file edit (per-edit hook)
- Roslyn analyzers as errors in CI (warnings locally for auto-fix cycle)

**Quality gate**: `dotnet format --verify-no-changes` + build with TreatWarningsAsErrors.

**Per-edit hook**: Auto-fix formatting on every C# file edit. Report unfixable issues back to Claude (exit 2).

**CI job**: `lint` — format check + analyzer build.

---

## Dimension 3: Type Safety

**Role**: Leverage C#'s strong type system. Enforce nullable reference types and strict analysis.

**What the tools must do**:
- Enforce nullable reference types (`<Nullable>enable</Nullable>`)
- Set analysis level to recommended or latest
- Treat nullable warnings as errors
- Enforce consistent use of `var` vs explicit types

**Default configuration**:
- Nullable: enable
- AnalysisLevel: latest-Recommended
- WarningsAsErrors for nullable categories (CS8600-CS8655)

**Adaptation**:
- Legacy codebase: start with `<Nullable>annotations</Nullable>`, migrate incrementally
- Interop-heavy: relax nullable in interop layers

**Quality gate**: Build with nullable warnings as errors.

**CI job**: `typecheck` — included in build job with strict analysis.

---

## Dimension 4: Security Analysis

**Role**: Static analysis for known vulnerability patterns, unsafe API usage, and security anti-patterns.

**What the tools must do**:
- Detect security vulnerabilities via Roslyn security analyzers
- Audit NuGet packages for known CVEs
- Match code against known vulnerability patterns (SQL injection, XSS, CSRF)
- Support framework-specific security rules (ASP.NET Core, Entity Framework)

**Adaptation**:
- Web apps (ASP.NET Core): add framework-specific security rulesets
- Libraries (no I/O): lighter security checking
- API projects: focus on input validation, authentication patterns

**Quality gate**: Run security analyzer build + `dotnet list package --vulnerable`.

**CI job**: `security` — security analyzer build + NuGet vulnerability audit.

---

## Dimension 5: Code Complexity

**Role**: Enforce measurable cyclomatic complexity limits to keep methods testable and maintainable.

**What the tool must do**:
- Measure cyclomatic complexity per method
- Fail when methods exceed threshold
- Report which methods are too complex

**Default thresholds**:
- No method above CC 10
- Consider refactoring at CC 7+

**Adaptation**:
- Early-stage project: accept CC ≤ 15 temporarily
- Legacy codebase: start at current max, tighten over time

**Quality gate**: Run complexity analysis on source projects.

---

## Dimension 6: Dead Code & Modernization

**Role**: Detect unused code and suggest modern C# idioms.

**What the tools must do**:
- Dead code: find unused private members, unreachable code, unnecessary usings
- Modernization: suggest modern C# patterns (pattern matching, records, file-scoped namespaces, collection expressions)

**Default configuration**:
- IDE analyzers for unused code (IDE0051, IDE0052, IDE0059, IDE0060)
- Style analyzers for modernization (IDE0090, IDE0180, IDE0300, etc.)
- Target project's C# language version

**Adaptation**:
- Library with public API: focus on private member detection only
- Multi-target: only suggest idioms available in minimum target framework

**Quality gate**: Build with IDE dead code analyzers as errors.

**CI job**: `deadcode` — build with dead code warnings promoted to errors.

---

## Dimension 7: Documentation

**Role**: Enforce XML documentation comments on public API members.

**What the tool must do**:
- Enforce `<summary>` comments on public types, methods, properties
- Exclude test projects, internal members, generated code
- Fail when public members lack documentation

**Default thresholds**:
- Libraries: all public members must be documented (CS1591 as error)
- Applications: public API surfaces only

**Adaptation**:
- Library: strict — CS1591 as error, generate XML doc file
- Internal application: warn only on public types
- Early-stage / prototype: disable, enable later

**Quality gate**: Build with documentation warnings as errors for library projects.

---

## Dimension 8: Architecture & Import Discipline

**Role**: Enforce dependency boundaries between projects. Detect architectural violations and dependency hygiene issues.

**What the tools must do**:
- Dependency analysis: verify project references follow declared architecture layers
- Namespace conventions: enforce namespace-to-folder alignment
- Circular dependency detection: find circular project/package references
- Dependency hygiene: detect unused NuGet packages

**Progressive activation**:

Architecture tests are never configured speculatively. The quality gate drives their introduction:

1. **No architecture tests defined**: the gate runs basic dependency validation only. Most projects start here.
2. **Circular dependency detected** → gate fails with a hint telling Claude to create architecture tests that formalize the project's layer structure, then fix the circular dependency.
3. **Architecture tests exist**: the gate enforces them on every run. Violations fail the gate like any other check.

**Adaptation**:
- Single-project solution: dependency analysis has nothing to find; effectively a no-op
- ASP.NET Core: when architecture tests are bootstrapped, hint should suggest layer rules (Controllers → Services → Repositories → Domain)
- Microservices: architecture tests per service, not solution-wide

**Quality gate**: Build architecture tests. Run circular reference detection. Check unused NuGet packages.

**Session start hook**: Run dependency hygiene check (non-blocking warnings).

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | NuGet vulnerability audit, dependency hygiene | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-fix formatting on each C# file edit | Yes (exit 2 for unfixable) |
| **Stop** | `quality-gate.sh` | Full quality gate (all enabled dimensions) | Yes (exit 2 → Claude fixes) |
| **Stop** | `auto-commit.sh` | Auto-commit and push if quality gate passes | No (push failure is non-blocking) |

### Fail-Fast Design

The quality gate runs checks **sequentially and stops at the first failure**. It does NOT collect all errors and report them at once. This is intentional:

- Claude fixes one issue at a time, then the gate re-runs
- Prevents "lost in the middle" — a long list of errors causes Claude to skip or half-fix items
- Each re-run confirms the previous fix didn't introduce new issues
- Faster feedback: common failures (tests, lint) are checked first

### Hook Output as Prompt

Hook stderr is fed directly to Claude as a prompt. The output must be structured to work well as an instruction, not just as a log message. Every failure output has three parts:

1. **What failed** — the check name and command that was run
2. **Tool output** — the raw error from the tool (file paths, line numbers, error codes)
3. **Diagnostic hint** — a specific instruction telling Claude how to investigate and fix this type of failure

The output ends with an **action directive** that tells Claude to fix the issue immediately rather than explain or stop.

### Output Examples

**Good** — a quality gate failure for a type check:
```
QUALITY GATE FAILED [dotnet-build]:
Command: dotnet build src/MyApp/MyApp.csproj --no-restore -warnaserror

src/MyApp/Services/UserService.cs(42,12): error CS8602: Dereference
  of a possibly null reference.

Hint: Read the file at the reported line number. Check for null
references and add null checks or use the null-conditional operator (?.).
Run 'dotnet build src/MyApp/MyApp.csproj' to re-check after fixing.

ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or
explain — read the failing file, edit the source code to resolve it,
and the quality gate will re-run automatically.
```

**Good** — a per-edit hook reporting a format issue:
```
Per-edit check found issues in src/MyApp/Services/UserService.cs:
FORMAT (dotnet format):
src/MyApp/Services/UserService.cs: formatting differs from .editorconfig
```

**Bad** — a wall of text with multiple failures (do NOT do this):
```
ERROR: 47 issues found
src/A.cs(1,1): warning IDE0073: File header missing
src/A.cs(5,5): warning CS8604: Possible null reference argument
src/B.cs(12,1): warning IDE0160: Use block-scoped namespace
... (43 more lines)
```

### Exit Code Convention

| Exit Code | Meaning | Claude Behavior |
|-----------|---------|-----------------|
| 0 | All checks passed | Claude proceeds normally |
| 1 | Error (script bug, tool not found) | Claude sees error but is not forced to fix |
| 2 | Check failed — stderr is a fix instruction | Claude reads stderr and must fix the issue, then the hook re-runs |

Exit code 2 is the key mechanism. It turns the hook into a feedback loop: fail → Claude fixes → hook re-runs → repeat until clean.

### Hint Writing Guidelines

Each tool check should have a diagnostic hint. Good hints:

- Tell Claude **which file to read** (use the paths from the tool output)
- Tell Claude **how to re-check** a single file after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit source code, not the test, unless the test is wrong)
- Are **specific to the tool** (not generic "fix the error" advice)

Example hints:
```
[dotnet test]   "Read the failing test file and the source it tests. Run
                 'dotnet test <test-project> --filter <test-name>' to see the
                 full error. Fix the source code, not the test, unless the
                 test itself is wrong."

[dotnet format] "Run 'dotnet format <solution> --include <file>' to auto-fix.
                 Check .editorconfig rules if the fix doesn't apply."

[dotnet build]  "Read the file at the reported line and column. Fix the
                 compiler error. Run 'dotnet build <project>' to re-check
                 a single project after fixing."
```

---

## Pre-commit Hooks

Separate from Claude Code hooks, git hooks can run on `git commit`:
- Format check (`dotnet format --verify-no-changes`)
- Build check (`dotnet build --no-restore`)

These catch issues in manual commits that bypass the Claude Code workflow.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Verify behavior, upload coverage |
| `lint` | Linting & Formatting | Verify formatting and analyzer rules |
| `build` | Type Safety + Dead Code | Build with strict analysis |
| `security` | Security Analysis | NuGet audit + security analyzers |

Jobs run on `push` to main and on pull requests to main.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with the project's .NET version and target framework
   - Framework-specific support needed (ASP.NET Core, Entity Framework, etc.)
   - Community adoption and maintenance status
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Integration with MSBuild / Roslyn analyzers (preferred over external tools)
3. **Present tool choices to the user** with rationale before configuring

---

## .NET-Specific Patterns

### MSBuild Property Centralization

.NET projects should use `Directory.Build.props` for shared MSBuild properties:
- Analyzer packages added once, inherited by all projects
- Nullable, AnalysisLevel, TreatWarningsAsErrors configured centrally
- Avoids duplication across .csproj files

### Roslyn Analyzers vs External Tools

Prefer Roslyn analyzers over external CLI tools when available:
- Analyzers run during `dotnet build` — no separate step needed
- Analyzers integrate with IDEs (real-time feedback)
- Analyzer warnings can be promoted to errors via .editorconfig
- External tools are only needed when no Roslyn equivalent exists

### .editorconfig as Central Config

.editorconfig controls both formatting and analyzer severity:
- Formatting rules (indentation, braces, spacing)
- Naming conventions (PascalCase, camelCase)
- Analyzer severity overrides (warning → error for CI)
- Supported natively by `dotnet format` and all Roslyn analyzers

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 8 code quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

**Sources**: Boris Cherny (creator of Claude Code) internal workflow recommendations; official Anthropic Claude Code best practices.

---

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**Why this matters**: Boris Cherny's team found that keeping CLAUDE.md to ~100 lines (≈2500 tokens) produces dramatically better results than longer files. Bloated instructions cause Claude to ignore important rules — they get lost in noise. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

**What to check**:
- Total size ≤ 2500 tokens (including content pulled in via `@path` imports and all rule files under `.claude/rules/`)
- No self-evident instructions ("write clean code", "follow best practices")
- No information Claude can infer by reading the code
- No file-by-file codebase descriptions or tutorials (link to docs instead)
- Includes required operational content: build/test commands, non-obvious conventions, environment quirks

**Default threshold**: 2500 tokens

---

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures — exit 1 logs the error but doesn't force Claude to fix it
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate ≥ 120s for large projects, per-edit ≤ 30s
- No hooks sourced from untrusted origins

---

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files ≤ 500 lines (move detailed reference to separate files)
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
- Agent definitions in `agents/` include focused `description` and `tools` restrictions
