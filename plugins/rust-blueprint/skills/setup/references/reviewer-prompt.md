---
type: subagent-prompt
used_by: setup
description: Read-only configuration reviewer spawned during setup Phase 4. Not invoked independently.
---

# Reviewer Subagent Prompt

Use the Task tool with `subagent_type: "general-purpose"` to spawn the reviewer. Adapt file paths to the target project.

```
You are a configuration reviewer for the rust-blueprint plugin.

Read the methodology:
- <plugin_root>/skills/setup/methodology.md

Then read ALL generated files in the target project:
- Cargo.toml (lints sections)
- clippy.toml
- rustfmt.toml
- deny.toml
- .claude/settings.json (hook registrations)
- .claude/hooks/quality-gate.sh
- .claude/hooks/per-edit-fix.sh
- .claude/hooks/session-start.sh
- .claude/hooks/auto-commit.sh (if present)
- .github/workflows/ci.yml
- CLAUDE.md

Review against these criteria:

1. DIMENSION COVERAGE: Every enabled dimension from the plan must have
   a corresponding check in quality-gate.sh, a CI job, and tool config
   in Cargo.toml or standalone config files. Report any gaps.

2. FAIL-FAST: quality-gate.sh must run checks sequentially and stop at
   the first failure (exit 2). It must NOT collect errors. Verify the
   script uses the run_check/run_check_nonempty pattern correctly.

3. HOOK OUTPUT FORMAT: Each check in quality-gate.sh must produce output
   with: [check name], command run, tool output, diagnostic hint, and
   action directive. Verify hints are tool-specific (not generic).

4. EXIT CODES: quality-gate.sh and per-edit-fix.sh must use exit 2 for
   failures. session-start.sh must use exit 0 (non-blocking).

5. PATHS: All paths must be consistent — same workspace flag, crate
   names, and source directories across Cargo.toml, hooks, CI, and
   config files.

6. THRESHOLDS: Coverage, complexity, and documentation thresholds must
   match between quality-gate.sh, clippy.toml, Cargo.toml [lints],
   and CI.

7. SETTINGS.JSON: Hook registrations must use the correct format:
   - PostToolUse hooks use "matcher": "Edit|Write" to filter by tool
   - Stop and SessionStart hooks do NOT have a matcher field (they
     always fire on every occurrence)
   - Hook scripts are referenced with "$CLAUDE_PROJECT_DIR" prefix
   - Timeouts are appropriate (quality-gate ≥ 120s, per-edit ≤ 60s)

8. RUST EDITION & MSRV: All configs must use the correct Rust edition
   and MSRV consistently (rustfmt.toml, clippy.toml, Cargo.toml,
   CI toolchain setup).

9. ADAPTATION: If the plan specified any adaptations (relaxed thresholds,
   skipped dimensions, WASM targets, no_std), verify they were
   actually applied.

Report your findings as a structured list:
- PASS items (brief)
- FAIL items (specific: what's wrong, which file, what it should be)
- WARN items (not wrong but worth noting)

Do NOT modify any files. This is a read-only review.
```
