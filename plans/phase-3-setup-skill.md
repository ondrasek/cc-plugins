# Phase 3: Setup Skill

## Status: Complete

## Goal

Create the main `/python-blueprint:setup` skill that reads the methodology and templates to intelligently configure a Python project.

## Deliverable

A working setup skill that analyzes a codebase and applies the quality methodology, adapting to the project's ecosystem.

## Files to Create

### Skill Definition

- **`skills/setup/SKILL.md`** — 5-phase workflow:
  1. **Analyze** — detect package manager, project structure, Python version, frameworks, existing tools
  2. **Plan** — select tools, determine thresholds, identify conflicts with existing config
  3. **Configure** — generate/merge pyproject.toml sections, create hooks, set up CI
  4. **Verify** — run the quality gate, ensure no regressions
  5. **Report** — summarize what was configured and any manual steps needed

### Plugin-Level Hook

- **`scripts/per-edit-fix.sh`** — plugin-level per-edit hook using `${CLAUDE_PLUGIN_ROOT}` for path resolution
- **`hooks/hooks.json`** — plugin-level hook registrations (PostToolUse for per-edit-fix)

## Design Decisions

- The setup skill uses `methodology.md`, `tool-catalog.md`, and `analysis-checklist.md` as its knowledge base
- Templates are adapted (not copied) — the skill reads templates and modifies them based on analysis results
- Plugin-level per-edit hook runs on any project using the plugin; quality gate and auto-commit are generated per-project
- The skill presents its plan to the user before making changes (interactive mode)

## Workflow Detail

### Phase 1: Analyze
```
- Read pyproject.toml / setup.py / setup.cfg
- Detect: uv / pip / poetry / pdm
- Detect: src layout vs flat
- Detect: Django / Flask / FastAPI / CLI / library
- Check Python version constraints
- List existing linters, formatters, type checkers
- Check for existing CI/CD
```

### Phase 2: Plan
```
- For each quality dimension, determine:
  - Which tool to use (may differ from default)
  - Configuration adjustments needed
  - Thresholds appropriate for project maturity
- Identify potential conflicts
- Present plan to user for approval
```

### Phase 3: Configure
```
- Merge tool configs into pyproject.toml
- Create/update .claude/hooks/ scripts
- Create/update .claude/settings.json
- Create/update .github/workflows/ci.yml
- Create/update .devcontainer/ if requested
- Create/update Makefile
- Create CLAUDE.md if missing
```

### Phase 4: Verify
```
- Run quality gate
- Report pass/fail for each check
- Suggest fixes for failures
```

### Phase 5: Report
```
- Summary of all changes made
- Manual steps needed (e.g., "add coverage config for your test runner")
- Next steps recommendations
```

## Verification

- Skill can be invoked with `/python-blueprint:setup`
- Skill successfully analyzes a fresh Python project
- Skill successfully analyzes a project with existing tooling
- Generated hooks work correctly
- Generated CI passes
