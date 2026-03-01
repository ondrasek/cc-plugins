# Vault Quality Methodology Framework

This document defines the shared principles, hook architecture, and Claude Code hygiene rules that apply across all vault quality skills.

The vault methodology defines 7 quality dimensions as **roles** (what needs to happen), not specific tools. The setup skill researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade standards. Every dimension can be relaxed for personal vaults, early-stage vaults, or imported collections.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the vault's ecosystem and plugin landscape.
5. **Incremental adoption** — Vaults can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## 7 Quality Dimensions (Roles)

Every vault methodology instance defines these 7 dimensions. Tools and thresholds vary by vault configuration.

| # | Dimension | Role |
|---|-----------|------|
| 1 | Frontmatter Integrity | Validate YAML frontmatter: required fields present, types correct, dates parseable, no duplicates |
| 2 | Link Integrity | Detect broken wikilinks, orphaned notes, unreachable attachments, missing embed targets |
| 3 | Naming Conventions | Enforce file/folder naming patterns: kebab-case, date prefixes, no special characters, consistent extensions |
| 4 | Template Compliance | Verify notes match their declared template: required sections present, heading hierarchy valid, placeholder tags resolved |
| 5 | Tag Hygiene | Detect orphan tags, enforce tag taxonomy, flag duplicates/near-duplicates, validate nested tag structure |
| 6 | Documentation Quality | Check spelling, prose style, heading consistency, sentence length, readability scores |
| 7 | Git Hygiene | Enforce .gitignore coverage, detect large binaries, validate commit message format, check for merge conflicts |

---

## Hook Architecture

The methodology uses three hook events:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | Vault detection, git hygiene warnings | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | Frontmatter validation, spelling | Yes (exit 2) |
| **Stop** | `quality-gate.sh` | Full quality gate (all 7 dimensions) | Yes (exit 2 → Claude fixes) |

### Fail-Fast Design

The quality gate runs checks **sequentially and stops at the first failure**. It does NOT collect all errors and report them at once. This is intentional:

- Claude fixes one issue at a time, then the gate re-runs
- Prevents "lost in the middle" — a long list of errors causes Claude to skip or half-fix items
- Each re-run confirms the previous fix didn't introduce new issues
- Faster feedback: common failures (frontmatter, spelling) are checked first

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
- Tell Claude **how to re-check** a single file after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit the note content, not the config, unless the config is wrong)
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

## Worktree Compatibility

Claude Code's `EnterWorktree` creates isolated worktrees at `.claude/worktrees/<name>/`, each with its own `$CLAUDE_PROJECT_DIR`. Vault hooks are designed to work correctly in both the main repository and linked worktrees.

### Isolation Guarantees

- **`$CLAUDE_PROJECT_DIR`** is set by Claude Code to the worktree root (not the main repo root). All hook templates use `${CLAUDE_PROJECT_DIR:-.}` for path resolution, ensuring they operate within the correct worktree.
- **Debug logs** are written to `${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log`, so each worktree gets its own log file.
- **Git operations** (`git status`, `git add`, `git commit`, `git push`) are inherently worktree-aware — they operate on the worktree's working tree and index automatically.

### Template Conventions

- **Path resolution**: Always use `${CLAUDE_PROJECT_DIR:-.}` — never `git rev-parse --show-toplevel` (which may resolve to the main worktree in edge cases).
- **Worktree identity**: Debug logs include `WORKTREE_ID="$(basename "${CLAUDE_PROJECT_DIR:-.}")"` in the log tag (e.g., `[quality-gate@fox]`). For the main repo this is the repo directory name; for a linked worktree it's the worktree name.

### Hook Behavior in Worktrees

| Hook | Worktree Behavior |
|------|-------------------|
| `session-start.sh` | Runs in worktree via `cd "${CLAUDE_PROJECT_DIR:-.}"` |
| `per-edit-fix.sh` | Operates on absolute file paths from tool input — worktree-safe by design |
| `quality-gate.sh` | All checks run against worktree files; debug log tagged with worktree ID |

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

## GitHub Workflow Catalog

Unlike code projects that use a fixed CI pipeline structure, Obsidian vaults benefit from a catalog of optional GitHub Actions workflows. The setup skill references `workflow-catalog.md` in the technology-specific skill to determine which workflows to propose based on vault characteristics.

Workflow categories include: vault quality checks, daily note generation, calendar sync, attachment optimization, and link validation. The setup skill researches `anthropics/claude-code-action` capabilities to propose AI-powered review workflows where appropriate.

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the vault already uses** — respect existing tool choices and community plugins
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Node.js CLI tools (most vault tooling is npm-based)
   - Community plugin ecosystem compatibility
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Obsidian compatibility (tools must not corrupt vault format)
3. **Present tool choices to the user** with rationale before configuring

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 7 vault quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**Why this matters**: Keeping CLAUDE.md to ~100 lines (approx. 2500 tokens) produces dramatically better results than longer files. Bloated instructions cause Claude to ignore important rules — they get lost in noise. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

**What to check**:
- Total size <= 2500 tokens (including content pulled in via `@path` imports and all rule files under `.claude/rules/`)
- No self-evident instructions ("write clean notes", "follow best practices")
- No information Claude can infer by reading the vault structure
- No file-by-file vault descriptions or tutorials (link to docs instead)
- Includes required operational content: vault conventions, non-obvious naming patterns, template locations

**Default threshold**: 2500 tokens

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures — exit 1 logs the error but doesn't force Claude to fix it
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths, not hardcoded absolute paths
- Timeouts are appropriate: quality gate >= 120s for large vaults, per-edit <= 30s
- No hooks sourced from untrusted origins
- Never use `git rev-parse --show-toplevel` for path resolution — use `${CLAUDE_PROJECT_DIR:-.}` instead (see [Worktree Compatibility](#worktree-compatibility))

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files <= 500 lines (move detailed reference to separate files)
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
- Agent definitions in `agents/` include focused `description` and `tools` restrictions
