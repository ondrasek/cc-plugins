# Quality Methodology Framework

This document defines the shared principles, hook architecture, and Claude Code hygiene rules that apply across all technology-specific quality methodologies.

Each technology methodology defines 9 quality dimensions as **roles** (what needs to happen), not specific tools. The setup skill researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for early-stage, prototype, or legacy projects.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem and language version.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## 9 Quality Dimensions (Roles)

Every technology methodology defines these 9 dimensions. Tools and thresholds vary by technology.

| # | Dimension | Role |
|---|-----------|------|
| 1 | Testing & Coverage | Verify code changes are backed by tests; enforce coverage thresholds |
| 2 | Linting & Formatting | Enforce consistent style; auto-fix on edit |
| 3 | Type Safety | Static type analysis or compiler strictness |
| 4 | Security Analysis | Detect vulnerability patterns and unsafe API usage |
| 5 | Code Complexity | Enforce cyclomatic/cognitive complexity limits |
| 6 | Dead Code & Modernization | Detect unused code; suggest modern idioms |
| 7 | Documentation | Enforce documentation coverage on public API |
| 8 | Architecture & Import Discipline | Enforce module boundaries and dependency hygiene |
| 9 | Version Discipline | Enforce semver 2.0; detect missing version bumps |

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | Dependency hygiene / environment checks | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Auto-fix formatting on each file edit | Yes (exit 2 for unfixable) |
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
- Tell Claude **how to re-check** a single file/module after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit source code, not the test, unless the test is wrong)
- Are **specific to the tool** (not generic "fix the error" advice)

### Quality Gate Template Pattern

Every quality gate script follows this pattern:

```bash
declare -A TOOL_HINTS
TOOL_HINTS=( [check-name]="Specific diagnostic hint for this tool..." )

fail() {
    local name="$1" cmd="$2" output="$3"
    local hint="${TOOL_HINTS[$name]:-}"
    echo "QUALITY GATE FAILED [$name]:" >&2
    echo "Command: $cmd" >&2
    echo "$output" >&2
    [ -n "$hint" ] && echo "Hint: $hint" >&2
    echo "ACTION REQUIRED: You MUST fix the issue shown above..." >&2
    exit 2
}

run_check()          { local name="$1"; shift; OUTPUT=$("$@" 2>&1) || fail "$name" "$*" "$OUTPUT"; }
run_check_nonempty() { local name="$1"; shift; OUTPUT=$("$@" 2>&1); [ -n "$OUTPUT" ] && fail "$name" "$*" "$OUTPUT"; }
```

---

## settings.json Format

The correct format for `.claude/settings.json` hook registrations:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/per-edit-fix.sh", "timeout": 60 }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/semver-check.sh", "timeout": 30 }]
      }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/quality-gate.sh", "timeout": 120 }] }
    ],
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh", "timeout": 30 }] }
    ]
  }
}
```

**Important matcher rules**:
- `PostToolUse` and `PreToolUse` support matchers that filter on tool name (regex): `"Edit|Write"`, `"Bash"`, `"mcp__.*"`
- `Stop`, `SessionStart`, `UserPromptSubmit`, `TeammateIdle`, `TaskCompleted` do **NOT** support matchers — they always fire on every occurrence. Do not add a `matcher` field to these events.
- Matchers are case-sensitive: `Edit|Write` not `edit|write`

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs. Technology-specific methodologies define the exact jobs, but the common pattern is:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Verify behavior, upload coverage |
| `lint` | Linting & Formatting | Verify style |
| `typecheck` | Type Safety | Verify types (where applicable) |
| `security` | Security Analysis | Verify safety |
| `deadcode` | Dead Code | Verify no dead code |
| `version` | Version Discipline | Verify semver format |

Jobs run on `push` to main and on pull requests to main.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with the project's language version
   - Framework-specific support needed
   - Community adoption and maintenance status
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Configuration centralization (prefer single config file where possible)
3. **Present tool choices to the user** with rationale before configuring

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 9 code quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**Why this matters**: Keeping CLAUDE.md to ~100 lines (≈2500 tokens) produces dramatically better results than longer files. Bloated instructions cause Claude to ignore important rules — they get lost in noise. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

**What to check**:
- Total size ≤ 2500 tokens (including content pulled in via `@path` imports and all rule files under `.claude/rules/`)
- No self-evident instructions ("write clean code", "follow best practices")
- No information Claude can infer by reading the code
- No file-by-file codebase descriptions or tutorials (link to docs instead)
- Includes required operational content: build/test commands, non-obvious conventions, environment quirks

**Default threshold**: 2500 tokens

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures — exit 1 logs the error but doesn't force Claude to fix it
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate ≥ 120s for large projects, per-edit ≤ 30s
- No hooks sourced from untrusted origins

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files ≤ 500 lines (move detailed reference to separate files)
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
- Agent definitions in `agents/` include focused `description` and `tools` restrictions
