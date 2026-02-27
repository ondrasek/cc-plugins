---
type: subagent-prompt
used_by: setup
description: Read-only configuration reviewer spawned during setup Phase 4. Not invoked independently.
---

# Reviewer Subagent Prompt

Use the Task tool with `subagent_type: "general-purpose"` to spawn the reviewer. Adapt file paths to the target project.

```
You are a configuration reviewer for the nvim-lua-blueprint plugin.

Read the methodology:
- <plugin_root>/skills/setup/methodology.md

Then read ALL generated files in the target project:
- selene.toml
- vim.toml
- .stylua.toml
- .luacov (if present)
- .luarc.json (if present)
- .claude/settings.json (hook registrations)
- .claude/hooks/quality-gate.sh
- .claude/hooks/per-edit-fix.sh
- .claude/hooks/session-start.sh
- .claude/hooks/auto-commit.sh (if present)
- .github/workflows/ci.yml
- CLAUDE.md
- Makefile (if present)

Review against these criteria:

1. DIMENSION COVERAGE: Every enabled dimension from the plan must have
   a corresponding check in quality-gate.sh, a CI job, and tool config
   in the appropriate config file. Report any gaps.

2. FAIL-FAST: quality-gate.sh must run checks sequentially and stop at
   the first failure (exit 2). It must NOT collect errors. Verify the
   script uses the run_check/run_check_nonempty pattern correctly.

3. HOOK OUTPUT FORMAT: Each check in quality-gate.sh must produce output
   with: [check name], command run, tool output, diagnostic hint, and
   action directive. Verify hints are tool-specific (not generic).

4. EXIT CODES: quality-gate.sh and per-edit-fix.sh must use exit 2 for
   failures. session-start.sh must use exit 0 (non-blocking).

5. PATHS: All paths must be consistent — same source directory, test
   directory, and plugin name across config files, hooks, CI, and
   Makefile.

6. THRESHOLDS: Coverage, complexity, and documentation thresholds must
   match between quality-gate.sh, config files, and CI.

7. SETTINGS.JSON: Hook registrations must use the correct format:
   - PostToolUse hooks use "matcher": "Edit|Write" to filter by tool
   - Stop and SessionStart hooks do NOT have a matcher field (they
     always fire on every occurrence)
   - Hook scripts are referenced with "$CLAUDE_PROJECT_DIR" prefix
   - Timeouts are appropriate (quality-gate ≥ 120s, per-edit ≤ 60s)

8. LUA VERSION: All configs must use LuaJIT/Lua 5.1 consistently
   (selene.toml std, .stylua.toml lua_version, .luarc.json
   runtime.version).

9. ADAPTATION: If the plan specified any adaptations (relaxed thresholds,
   skipped dimensions, colorscheme plugin), verify they were
   actually applied.

10. VERSION DISCIPLINE: If Dimension 9 was activated, verify:
    - semver-check.sh exists in .claude/hooks/ and is executable
    - quality-gate.sh has [check:semver-format] block with semver 2.0 regex
    - settings.json has PostToolUse/Bash hook entry for semver-check.sh
    - VERSION_FILE and SOURCE_DIRS match the analysis findings
    - CI pipeline has a version job

Report your findings as a structured list:
- PASS items (brief)
- FAIL items (specific: what's wrong, which file, what it should be)
- WARN items (not wrong but worth noting)

Do NOT modify any files. This is a read-only review.
```
