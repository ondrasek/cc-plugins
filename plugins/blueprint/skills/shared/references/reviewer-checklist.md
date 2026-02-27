# Reviewer Checklist

This checklist defines the 10 review criteria for the Phase 4 reviewer subagent. Technology-specific `reviewer-prompt.md` files extend this with language-specific file paths and tool names.

---

## Review Criteria

### 1. Dimension Coverage

Every enabled dimension must have:
- A quality gate check in `quality-gate.sh`
- A CI job (or shared job) in `ci.yml`
- Tool configuration in the appropriate config file(s)

Flag any dimension that's enabled but missing one of these three.

### 2. Fail-Fast Compliance

The quality gate must:
- Run checks **sequentially** (not in parallel)
- Stop at the **first failure** (exit 2)
- Use the `run_check` / `run_check_nonempty` pattern
- Not collect and report multiple errors

### 3. Hook Output Format

Every quality gate failure must include:
- **Check name** in brackets: `QUALITY GATE FAILED [name]:`
- **Command** that was run
- **Tool output** (raw error)
- **Diagnostic hint** — must be tool-specific, not generic "fix the error" advice
- **Action directive** — `ACTION REQUIRED: You MUST fix the issue...`

### 4. Exit Codes

- Quality gate and per-edit hook: exit 2 on check failure
- Session start: always exit 0 (non-blocking warnings)
- Auto-commit: exit 0 on push failure (non-blocking)

### 5. Path Consistency

Source directory, test directory, and project paths must be consistent across:
- Quality gate script
- CI pipeline
- Tool configuration files
- settings.json hook commands

### 6. Threshold Consistency

Thresholds (coverage, complexity, documentation) must match across:
- Quality gate script
- Tool configuration files
- CI pipeline

### 7. settings.json Format

Verify:
- `PostToolUse` and `PreToolUse` have matchers; other events do NOT
- All script paths use `"$CLAUDE_PROJECT_DIR"` prefix
- Timeouts are appropriate (quality gate ≥ 120s, per-edit ≤ 60s, session-start ≤ 30s)
- Matchers are case-sensitive correct

### 8. Language/Runtime Consistency

Language version, runtime version, and edition must be consistent across:
- Tool configuration files
- CI pipeline
- Quality gate script

### 9. Adaptations Applied

If the plan specified adaptations (relaxed thresholds, skipped dimensions, framework-specific rules), verify they are actually reflected in the generated configuration.

### 10. Version Discipline

If Dimension 9 is active:
- `semver-check.sh` exists and is executable
- Quality gate has a `semver-format` check block
- settings.json has `PostToolUse/Bash` entry for semver-check
- CI has a `version` job
- If `publish = false` or equivalent: bump enforcement is skipped but format validation remains
