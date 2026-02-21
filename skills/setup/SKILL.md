# /python-blueprint:setup

Analyze a Python project and intelligently configure the quality methodology — hooks, CI, and tool configs.

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — quality dimensions (roles), adaptation rules, hook architecture
- `skills/setup/analysis-checklist.md` — what to check in the target codebase

Templates in `skills/setup/templates/` are **annotated examples** — they demonstrate structural patterns (hook architecture, CI job layout, Makefile targets) using current tools as examples. During the Configure phase, use templates for the patterns but substitute the tools chosen during research.

## Workflow

Execute these 6 phases in order. Present findings and plan to the user before making changes.

### Phase 1: Analyze

Examine the target project to understand its ecosystem. Follow `analysis-checklist.md` systematically.

**Steps**:

1. **Package manager** — Check for `uv.lock`, `poetry.lock`, `pdm.lock`, `Pipfile.lock`, `requirements.txt`. Read `pyproject.toml` for `[tool.uv]` or `[tool.poetry]`.

2. **Python version** — Check `pyproject.toml` `requires-python`, `.python-version`, Dockerfile.

3. **Project structure** — Determine if `src/` layout or flat layout. Find the main package directory. Locate `tests/`.

4. **Framework** — Scan dependencies in `pyproject.toml` for django, flask, fastapi, click, typer, celery, sqlalchemy, pydantic.

5. **Existing tools** — Check `pyproject.toml` for `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest]`, `[tool.bandit]`, etc. Check for `pyrightconfig.json`, `.flake8`, `.mypy.ini`, `setup.cfg`, `tox.ini`.

6. **Existing CI** — Check `.github/workflows/`, `.gitlab-ci.yml`, etc.

7. **Existing Claude Code config** — Check `.claude/settings.json`, `.claude/hooks/`, `CLAUDE.md`.

8. **Project maturity** — Estimate LOC, count test files, check git history depth.

**Output**: Present a structured summary to the user:
```
Package manager: uv
Python version: 3.13
Project structure: src layout (src/mypackage/)
Framework: FastAPI + Pydantic
Project size: ~2,500 LOC, 45 test files
Existing tools: ruff (configured), pytest (configured), mypy (basic)
Missing dimensions: security, complexity, dead code, documentation, architecture
CI: GitHub Actions (test + lint jobs exist)
DevContainer: none
```

### Phase 2: Plan

Based on the analysis, determine what to configure. Apply adaptation rules from `methodology.md`.

**Steps**:

1. **Research and select tools** — For each of the 8 quality dimensions:
   - Check if the project already uses a tool for this role (keep it if so)
   - For unfilled roles, use WebSearch to research current best-in-class Python tools
   - Consider: Python version compatibility, framework support, speed, community adoption, pyproject.toml support
   - Determine configuration adjustments needed (Python version, paths, thresholds)
   - Decide whether to enable or skip this dimension (with rationale)

2. **Determine thresholds** — Based on project maturity:
   - Coverage threshold (40–90%)
   - Docstring coverage threshold (50–90%)
   - Complexity grade (B–D)
   - Vulture confidence (80–95%)

3. **Plan file changes** — List every file that will be created or modified:
   - `pyproject.toml` — sections to add/merge
   - `.claude/hooks/` — scripts to create
   - `.claude/settings.json` — hook registrations
   - `.github/workflows/ci.yml` — CI pipeline
   - `.pre-commit-config.yaml` — pre-commit hooks
   - `Makefile` — development commands
   - `CLAUDE.md` — project instructions
   - `pyrightconfig.json` — type checker config
4. **Identify conflicts** — Flag any existing config that conflicts with the methodology and propose resolution.

**Output**: Present the complete plan to the user and wait for approval before proceeding. Ask about optional items (auto-commit hook, style-guide check).

### Phase 3: Configure

Apply the approved plan. Templates in `skills/setup/templates/` are **annotated examples** — they demonstrate the structural patterns and architecture, but the specific tools shown are examples, not requirements. Use the templates as starting points and substitute the tools chosen during research.

**Steps**:

1. **Merge tool configs into pyproject.toml** — Read `templates/pyproject-tools.toml` for structure reference. Generate `[tool.*]` sections for the actual researched tools (not necessarily the ones in the template). Substitute variables, merge into existing `pyproject.toml`. Preserve existing config, only add new sections.

2. **Create hook scripts** — Read each template (`quality-gate.sh`, `per-edit-fix.sh`, `auto-commit.sh`, `session-start.sh`) for the patterns (run_check/fail mechanism, hint format, exit codes). Substitute the researched tool commands, write tool-specific hints, remove disabled check sections, write to `.claude/hooks/`. Make executable.

3. **Create/update settings.json** — Read `templates/settings.json`, customize hook paths and timeouts, merge into existing `.claude/settings.json`.

4. **Create/update CI pipeline** — Read `templates/ci.yml` for job structure. Substitute researched tool commands, remove/add jobs based on enabled dimensions. If CI exists, merge jobs into existing pipeline.

5. **Create Makefile** — Read `templates/Makefile` for target naming conventions. Substitute researched tool commands. If Makefile exists, merge targets.

6. **Create type checker config** — Only if the chosen type checker requires a standalone config file (e.g., `pyrightconfig.json` for pyright). Type checkers that configure via `pyproject.toml` don't need this.

7. **Create .pre-commit-config.yaml** — Add pre-commit hooks for the chosen linter/formatter. If one exists, merge hooks.

8. **Create/update CLAUDE.md** — If no CLAUDE.md exists, create from `templates/CLAUDE.md`. If one exists, append methodology reference section.

9. **Install dependencies** — Run the package manager's install/sync command to install new dev dependencies.

10. **Install pre-commit hooks** — Run `pre-commit install`.

11. **(Optional) Create style-guide check** — If project uses click/typer, read `templates/style-guide-check.sh`, substitute variables, write to `.claude/hooks/`.

### Phase 4: Review

Spawn a **reviewer subagent** to audit the generated configuration against the methodology. The reviewer is a separate agent that reads the methodology and all generated files, then reports issues back to the setup skill for correction.

**Why a subagent**: The setup skill has been making decisions and writing files — it has cognitive momentum. A fresh agent reading the methodology and the output with no prior context catches mistakes the setup skill is blind to: inconsistencies, missing dimensions, hook output that doesn't follow the prompt format, thresholds that don't match the plan, etc.

**How to spawn**: Use the Task tool with `subagent_type: "general-purpose"`:

```
Task(
  description: "Review blueprint configuration",
  subagent_type: "general-purpose",
  prompt: <see below>
)
```

**Reviewer prompt** (adapt paths to the target project):

```
You are a configuration reviewer for the python-blueprint plugin.

Read the methodology:
- <plugin_root>/skills/setup/methodology.md

Then read ALL generated files in the target project:
- pyproject.toml (tool config sections)
- .claude/settings.json (hook registrations)
- .claude/hooks/quality-gate.sh
- .claude/hooks/per-edit-fix.sh
- .claude/hooks/session-start.sh
- .claude/hooks/auto-commit.sh (if present)
- .github/workflows/ci.yml
- .pre-commit-config.yaml
- pyrightconfig.json (if present)
- Makefile
- CLAUDE.md

Review against these criteria:

1. DIMENSION COVERAGE: Every enabled dimension from the plan must have
   a corresponding check in quality-gate.sh, a CI job, and tool config
   in pyproject.toml. Report any gaps.

2. FAIL-FAST: quality-gate.sh must run checks sequentially and stop at
   the first failure (exit 2). It must NOT collect errors. Verify the
   script uses the run_check/run_check_nonempty pattern correctly.

3. HOOK OUTPUT FORMAT: Each check in quality-gate.sh must produce output
   with: [check name], command run, tool output, diagnostic hint, and
   action directive. Verify hints are tool-specific (not generic).

4. EXIT CODES: quality-gate.sh and per-edit-fix.sh must use exit 2 for
   failures. session-start.sh must use exit 0 (non-blocking).

5. PATHS: All paths must be consistent — same source dir, test dir,
   and package name across pyproject.toml, hooks, CI, and pyrightconfig.

6. THRESHOLDS: Coverage, docstring, and complexity thresholds must match
   between quality-gate.sh, pyproject.toml, and CI.

7. SETTINGS.JSON: Hook registrations must point to the correct scripts
   with appropriate timeouts and matchers.

8. PACKAGE MANAGER: All commands must use the correct package manager
   prefix consistently (uv run, poetry run, etc.).

9. ADAPTATION: If the plan specified any adaptations (relaxed thresholds,
   skipped dimensions, framework-specific config), verify they were
   actually applied.

Report your findings as a structured list:
- PASS items (brief)
- FAIL items (specific: what's wrong, which file, what it should be)
- WARN items (not wrong but worth noting)

Do NOT modify any files. This is a read-only review.
```

**After review**: Read the reviewer's findings. Fix any FAIL items. Re-spawn the reviewer if significant changes were made. Proceed to Verify only when the review is clean.

### Phase 5: Verify

Run the quality gate to confirm everything works.

**Steps**:

1. Run the newly created quality gate script: `.claude/hooks/quality-gate.sh`
2. Collect pass/fail results for each check
3. For any failures, determine if they are:
   - **Pre-existing issues** — code quality gaps that exist before the methodology was applied
   - **Configuration issues** — problems with the generated config that need fixing

**Output**: Report results to the user, distinguishing pre-existing issues from config problems. Fix any config problems. For pre-existing issues, suggest next steps.

### Phase 6: Report

Summarize everything that was done.

**Output**:

```
## Setup Complete

### Configured Dimensions
- [x] Testing & Coverage (pytest, 80% threshold)
- [x] Linting & Formatting (ruff, codespell)
- [x] Type Safety (pyright, mypy, ty)
- [x] Security Analysis (bandit, semgrep)
- [x] Code Complexity (xenon, grade B)
- [x] Dead Code & Modernization (vulture, refurb)
- [x] Documentation (interrogate, 70% threshold)
- [x] Architecture (import-linter, deptry)

### Files Created/Modified
- pyproject.toml — added tool configs and dev dependencies
- .claude/hooks/ — quality-gate.sh, per-edit-fix.sh, auto-commit.sh, session-start.sh
- .claude/settings.json — hook registrations
- .github/workflows/ci.yml — CI pipeline
- Makefile — development commands
- pyrightconfig.json — type checker config
- .pre-commit-config.yaml — pre-commit hooks

### Quality Gate Results
- 12/15 checks passing
- 3 pre-existing issues to address:
  - coverage: 62% (below 80% threshold)
  - interrogate: 45% docstring coverage (below 70%)
  - vulture: 3 unused functions detected

### Next Steps
- Add tests to reach 80% coverage
- Add docstrings to public functions
- Remove or whitelist unused code detected by vulture
- Run `/python-blueprint:audit` periodically to check progress
```

## Important Notes

- Always present analysis and plan to the user before making changes
- Never overwrite user's existing configurations without asking
- Merge, don't replace — preserve existing pyproject.toml sections, CI jobs, etc.
- Use the package manager detected in analysis (don't assume uv)
- All hook scripts must be executable (chmod +x)
- Paths in templates use `$CLAUDE_PROJECT_DIR` which Claude Code resolves at runtime
