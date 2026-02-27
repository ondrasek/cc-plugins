# Audit Workflow

Read-only — does not modify any files.

The audit skill compares a project's current quality setup against the 9-dimension methodology and reports gaps. Each technology-specific audit SKILL.md provides the tech-specific detection details while following this shared structure.

---

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1):
- Detect language version, project structure, targets
- Inventory existing tool configurations
- Check for existing hooks in `.claude/settings.json`
- Check for CI pipeline
- Check for installed tools

### 2. Compare Against Methodology

For each of the 9 quality dimensions from the technology-specific `methodology.md`, check whether the role is filled by any tool:

1. **Testing & Coverage** — Is there a test suite? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is a linter configured? Is a formatter configured? Is auto-format on edit?
3. **Type Safety** — Is type checking configured? Are strict settings enabled?
4. **Security Analysis** — Is security scanning configured? Are dependencies audited?
5. **Code Complexity** — Is complexity measurement configured? What threshold?
6. **Dead Code & Modernization** — Are dead code lints enabled? Are modernization suggestions active?
7. **Documentation** — Is documentation coverage enforced? What threshold?
8. **Architecture** — Is dependency hygiene checked? Are module boundaries enforced?
9. **Version Discipline** — Is there a version field? Is it semver 2.0? Is bump enforcement configured?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event:
- SessionStart → dependency/environment checks (non-blocking)
- PostToolUse (Edit|Write) → per-edit auto-format
- Stop → quality gate (all enabled dimensions)
- Stop → auto-commit (optional)
- PostToolUse (Bash) → semver bump enforcement (blocking, only if Dimension 9 active)

### 4. Check CI Coverage

Verify CI pipeline has a job for each enabled dimension (technology-specific job names).

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Testing & Coverage | Configured | ... | ... |
| ... | ... | ... | ... |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [ ] Stop (quality gate) — not configured
- ...

### CI Coverage
- [x] test
- [ ] lint — missing
- ...

### Recommendations
1. Run the setup skill to configure missing dimensions
2. ...
```

---

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where project-specific thresholds may be appropriate
- Flag outdated tools that have been superseded by better alternatives
- Report both missing dimensions and misconfigured existing tools
