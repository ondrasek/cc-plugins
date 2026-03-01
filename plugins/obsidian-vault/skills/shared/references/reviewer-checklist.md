# Reviewer Checklist

This checklist defines the 8 review criteria for the Phase 4 reviewer subagent. The vault-specific `reviewer-prompt.md` extends this with vault-specific file paths and tool names.

---

## Review Criteria

### 1. Dimension Coverage

Every enabled dimension must have:
- A quality gate check in `quality-gate.sh`
- Tool configuration in the appropriate config file(s)
- Optionally, a GitHub Actions workflow (from the workflow catalog)

Flag any dimension that's enabled but missing a quality gate check or tool configuration.

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

### 5. Path Consistency

Vault paths (daily notes directory, templates directory, attachments directory) must be consistent across:
- Quality gate script
- Tool configuration files
- GitHub Actions workflows
- settings.json hook commands
- .gitignore patterns

### 6. Threshold Matching

Thresholds (spelling tolerance, readability scores, frontmatter strictness) must match across:
- Quality gate script
- Tool configuration files
- GitHub Actions workflows (if applicable)

### 7. settings.json Format

Verify:
- `PostToolUse` and `PreToolUse` have matchers; other events do NOT
- All script paths use `"$CLAUDE_PROJECT_DIR"` prefix
- Timeouts are appropriate (quality gate >= 120s, per-edit <= 60s, session-start <= 30s)
- Matchers are case-sensitive correct

### 8. Workflow Configuration Consistency

If GitHub Actions workflows were created:
- Workflow triggers are appropriate (push to main, pull requests, schedule for automated tasks)
- Tool versions in workflows match local tool versions
- Vault path references in workflows match the actual vault structure
- Secrets and permissions are correctly scoped
- `anthropics/claude-code-action` is configured correctly (if used)
