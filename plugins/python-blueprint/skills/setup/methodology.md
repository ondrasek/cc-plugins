# Python Quality Methodology

This document defines the quality methodology applied by the `python-blueprint` plugin. It is organized into 9 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem and Python version.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**Role**: Verify that code changes are backed by tests. Measure and enforce test coverage thresholds.

**What the tool must do**:
- Discover and run test files
- Stop on first failure (fail-fast mode)
- Measure line coverage against a threshold
- Report uncovered lines

**Default thresholds**:
- Minimum coverage: 95%
- Test directory: `tests/`

**Adaptation**:
- New project (< 500 LOC): 80%
- Legacy project adopting methodology: start at current coverage, increase incrementally

**Quality gate**: Run tests (fail-fast), then run coverage check against threshold.

**CI job**: `test` — run tests with coverage, upload report on PRs.

---

## Dimension 2: Linting & Formatting

**Role**: Enforce consistent code style. Auto-detect and fix common bugs, anti-patterns, and import ordering. Catch typos.

**What the tools must do**:
- Lint: check for style errors, unused imports, undefined names, import ordering, deprecated patterns, common bugs
- Format: enforce consistent whitespace, quotes, line length
- Spell check: catch typos in identifiers, strings, comments (auto-fixable)

**Default configuration**:
- Line length: 100
- Target: project's minimum Python version
- Auto-fix on every file edit (per-edit hook)

**Quality gate**: Lint check + format check on source and test directories.

**Per-edit hook**: Auto-fix lint, format, and spelling on every Python file edit. Report unfixable issues back to Claude (exit 2).

**CI job**: `lint` — lint check + format check.

---

## Dimension 3: Type Safety

**Role**: Static type analysis to catch type errors before runtime.

**What the tools must do**:
- Analyze type annotations and infer types
- Report type mismatches, missing annotations, incompatible assignments
- Support gradual typing (can work with partially-typed codebases)

**Default configuration**:
- Standard/strict mode for annotated code
- Relaxed checking for test files

**Adaptation**:
- Untyped codebase: start with basic mode, skip strict checking
- Gradual typing: check only annotated modules
- Framework-specific: add type stubs for Django, Pydantic, etc.

**Quality gate**: Run type checker(s) on source directory.

**CI job**: `typecheck` — run primary type checker.

---

## Dimension 4: Security Analysis

**Role**: Static analysis for known vulnerability patterns, unsafe API usage, and security anti-patterns.

**What the tools must do**:
- Detect hardcoded secrets, shell injection, insecure crypto
- Match code against known vulnerability patterns
- Support framework-specific security rules (Django, Flask, etc.)

**Adaptation**:
- Web apps: add framework-specific rulesets
- Libraries (no I/O): lighter security checking
- Slow scanners: consider CI-only for large codebases

**Quality gate**: Run security scanner(s) on source directory.

**CI job**: `security` — run primary security scanner.

---

## Dimension 5: Code Complexity

**Role**: Enforce measurable cyclomatic complexity limits to keep functions testable and maintainable.

**What the tool must do**:
- Measure cyclomatic complexity per function, per module, and project-wide
- Fail when functions exceed threshold
- Report which functions are too complex

**Default thresholds**:
- No function above CC 10 (grade B)
- Module averages in CC 1–5 range (grade A)
- Project-wide average in CC 1–5 range (grade A)

**Adaptation**:
- Early-stage project: accept CC ≤ 15 temporarily
- Legacy codebase: start at current max, tighten over time

**Quality gate**: Run complexity checker on source directory.

---

## Dimension 6: Dead Code & Modernization

**Role**: Detect unused code and suggest modern Python idioms.

**What the tools must do**:
- Dead code: find unused functions, variables, imports, classes
- Modernization: suggest idiomatic replacements for outdated patterns

**Default configuration**:
- Dead code confidence: 80% (trade-off between false positives and coverage)
- Modernization: target project's Python version

**Adaptation**:
- Library with public API: raise confidence threshold to reduce false positives on exported symbols, or maintain a whitelist
- Plugin/dynamic architecture: whitelist dynamically-loaded code

**Quality gate**: Run dead code detector + modernizer on source directory (nonempty output = fail).

**CI job**: `deadcode` — run dead code detector.

---

## Dimension 7: Documentation

**Role**: Enforce docstring coverage on public functions, classes, and modules.

**What the tool must do**:
- Measure docstring coverage percentage
- Exclude test files, private/magic methods, `__init__`
- Fail when coverage drops below threshold

**Default thresholds**:
- Minimum docstring coverage: 70%

**Adaptation**:
- Library: raise to 90% (consumers depend on docstrings)
- Early-stage / prototype: lower to 50%
- Internal tool: 60%

**Quality gate**: Run docstring coverage checker on source directory.

---

## Dimension 8: Architecture & Import Discipline

**Role**: Enforce import boundaries between modules. Detect dependency hygiene issues.

**What the tools must do**:
- Circular import detection: find circular dependencies between modules (always active)
- Import contract enforcement: enforce declared layer boundaries (activated by contracts existing)
- Dependency hygiene: detect unused, missing, or transitive dependencies in `pyproject.toml`

**Progressive activation**:

Import contracts are never configured speculatively. The quality gate drives their introduction:

1. **No contracts defined**: the gate runs circular import detection only. Most projects start here.
2. **Circular import detected** → gate fails with a hint telling Claude to define import contracts in `pyproject.toml` that formalize the project's package structure, then fix the circular dependency.
3. **Contracts exist**: the gate enforces them on every run. Violations fail the gate like any other check.

This means a single-module project or a new project never sees import linting — until a real violation demands it.

**Adaptation**:
- Single-module project: circular import detection has nothing to find; effectively a no-op
- Django: when contracts are bootstrapped, hint should suggest layer contracts (views → services → models)
- Monorepo: contracts per package, not project-wide

**Quality gate**: Run circular import detection. If contracts exist, also run import contract enforcement.

**Session start hook**: Run dependency hygiene check (non-blocking warnings).

---

## Dimension 9: Version Discipline

**Role**: Enforce semver 2.0 on the project's version string. Detect missing version bumps when source code changes are committed.

**What the tools must do**:
- Validate the project's version string follows semver 2.0 format (MAJOR.MINOR.PATCH with optional pre-release and build metadata)
- On commit, compare the version at the branch base vs HEAD — block if source files changed but the version did not

**Progressive activation**:

Version discipline is never configured speculatively. The quality gate drives its introduction:

1. **No version file detected**: the dimension is skipped entirely. Most scripts and internal tools start here.
2. **Version file exists, no packaging intent**: format validation only (quality gate). Catches typos and non-semver strings.
3. **Version file + packaging intent**: both format validation (quality gate) AND bump enforcement (PostToolUse/Bash hook on `git commit`).

Detection signals for Python:
- **Version file**: `pyproject.toml` with `project.version` or `tool.poetry.version`; `__version__` in source
- **Packaging intent**: `[build-system]` section with `build-backend`, `tool.poetry.packages`, `[project.urls]` with PyPI link
- **Dynamic versioning**: `dynamic = ["version"]` → skip bump enforcement (version is managed by the build system, e.g., `setuptools-scm`, `hatch-vcs`)

**Default configuration**:
- Semver 2.0 regex validation in the quality gate
- PostToolUse/Bash hook (`semver-check.sh`) that fires only on `git commit`

**Adaptation**:
- Dynamic versioning (`setuptools-scm`, `hatch-vcs`): skip bump enforcement, keep format validation
- Monorepo with multiple packages: one check per package version
- Pre-1.0 project: no special treatment — semver pre-release tags handle instability

**Quality gate**: Validate version string matches semver 2.0 regex.

**PostToolUse/Bash hook**: On `git commit`, compare version at merge-base vs HEAD. Block if source dirs changed but version is unchanged.

**CI job**: `version` — extract and validate version string format.

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | Dependency hygiene check | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-fix lint, format, spelling on each Python file edit | Yes (exit 2 for unfixable) |
| **Stop** | `quality-gate.sh` | Full quality gate (all enabled dimensions) | Yes (exit 2 → Claude fixes) |
| **Stop** | `auto-commit.sh` | Auto-commit and push if quality gate passes | No (push failure is non-blocking) |
| **PostToolUse** (Bash) | `semver-check.sh` | Block commits where source changed but version was not bumped | Yes (exit 2 for unbumped) |

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

**Good** — a quality gate failure for a type checker:
```
QUALITY GATE FAILED [pyright]:
Command: uv run pyright src/

src/mypackage/api.py:42:12 - error: Argument of type "str | None" cannot be
  assigned to parameter "name" of type "str" in function "create_user"
    "str | None" is not assignable to "str" (reportGeneralClassErrors)

Hint: Read the file at the reported line number. Check type annotations,
imports, and function signatures. Run 'uv run pyright src/mypackage/api.py'
to re-check a single file after fixing.

ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or
explain — read the failing file, edit the source code to resolve it,
and the quality gate will re-run automatically.
```

**Good** — a per-edit hook reporting an unfixable lint issue:
```
Per-edit check found issues in src/mypackage/utils.py:
LINT (ruff):
src/mypackage/utils.py:15:1: F811 Redefinition of unused `parse_config`
  from line 8
```

**Bad** — a wall of text with multiple failures (do NOT do this):
```
ERROR: 47 issues found
src/a.py:1: E302 expected 2 blank lines
src/a.py:5: F401 unused import
src/b.py:12: E501 line too long
src/b.py:15: F401 unused import
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
[pytest]    "Read the failing test file and the source it tests. Run
             'uv run pytest path/to/test.py::test_name -x --tb=long'
             to see the full traceback. Fix the source code, not the
             test, unless the test itself is wrong."

[ruff]      "Run 'uv run ruff check src/ --output-format=full' for
             detailed explanations. Most issues are auto-fixable with
             'uv run ruff check --fix'."

[xenon]     "The reported function has cyclomatic complexity above the
             threshold. Read the function and extract helper functions
             to reduce branching."
```

---

## Pre-commit Hooks

Separate from Claude Code hooks, `pre-commit` runs on `git commit`:
- Lint check
- Format check

These catch issues in manual commits that bypass the Claude Code workflow.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Verify behavior, upload coverage |
| `lint` | Linting & Formatting | Verify style |
| `typecheck` | Type Safety | Verify types |
| `security` | Security Analysis | Verify safety |
| `deadcode` | Dead Code | Verify no dead code |
| `version` | Version Discipline | Verify semver format |

Jobs run on `push` to main and on pull requests to main.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with the project's Python version
   - Framework-specific support needed
   - Community adoption and maintenance status
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Configuration via `pyproject.toml` (preferred over standalone config files)
3. **Present tool choices to the user** with rationale before configuring

---

## Style Guide (CLI Projects)

For projects using CLI frameworks (click, typer, etc.):
1. **No ASCII splitter lines** — no `===`, `---`, `***` in echo/print calls
2. **Section headings** — use styled, bold, colored output
3. **Emoji prefixes** — section headings should include an emoji

This is an optional check, only enabled when a CLI framework is detected.

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 9 code quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

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

**Actionable checks**:

| Hook Event | Check | Behavior |
|-----------|-------|----------|
| **Stop** | Count tokens in CLAUDE.md (resolve `@imports`) + all `.claude/rules/` files | Warn if > 2500 tokens |
| **PostToolUse** (Edit\|Write matching `CLAUDE.md` or `.claude/rules/`) | Same token count | Immediate feedback on edits |

**Default threshold**: 2500 tokens

**Adaptation**:
- Monorepo with nested CLAUDE.md files: each file ≤ 2500, not cumulative
- Complex project: split into CLAUDE.md + `@imported` reference files, but keep resolved total under 2500
- New project: start minimal, add rules only when Claude makes a mistake that needs correcting

---

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**Why this matters**: A misconfigured hook silently breaks the quality loop — scripts that aren't executable never run, wrong exit codes don't trigger fixes, case-sensitive matcher typos skip checks entirely.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures — exit 1 logs the error but doesn't force Claude to fix it
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate ≥ 120s for large projects, per-edit ≤ 30s
- No hooks sourced from untrusted origins

**Actionable checks**:

| Hook Event | Check | Behavior |
|-----------|-------|----------|
| **SessionStart** | Validate all registered hook scripts exist and are executable | Warn (non-blocking) on missing or non-executable scripts |
| **SessionStart** | Check for common matcher typos (lowercase tool names) | Warn on likely case errors |

**Rules** (for hook authors):
- Every `run_check` block must include a tool-specific diagnostic hint, not generic "fix the error" advice
- Hook output is a prompt: what failed → tool output → hint → action directive
- Quality gate must be fail-fast (one error at a time, sequential checks)

---

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**Why this matters**: The context window is the most important resource in AI-assisted development (Anthropic docs). LLM performance degrades as context fills. Skill descriptions load into context automatically; bloated skills waste tokens and crowd out the actual work. Boris Cherny recommends using subagents for heavy investigation to keep the main conversation clean.

**What to check**:
- Skill SKILL.md files ≤ 500 lines (move detailed reference to separate files)
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
- Agent definitions in `agents/` include focused `description` and `tools` restrictions

**Actionable checks**:

| Hook Event | Check | Behavior |
|-----------|-------|----------|
| **SessionStart** | Measure line count of all SKILL.md files | Warn (non-blocking) if any exceed 500 lines |

**Progressive disclosure pattern** (3 levels):

1. **Frontmatter** (`name`, `description`) — always loaded into context for skill discovery
2. **SKILL.md body** — loaded when skill is invoked; keep to workflow essentials
3. **References** (`references/`, `templates/`) — loaded on demand by the skill body's instructions

**Rules**:
- Never inline large prompt templates in SKILL.md — extract to `references/`
- Subagents spawned by skills should use `tools` restrictions to limit their scope
- Use `/clear` between unrelated tasks; use subagents for exploratory research
