---
name: setup
description: Analyzes a .NET/C# project and configures 8-dimension quality methodology including hooks, CI, and tool configs. Use when user says "set up quality tools", "configure analyzers", "add CI pipeline", "dotnet quality", or wants to apply coding standards to a .NET project.
metadata:
  version: 0.1.0
  author: ondrasek
---

# Setup

## Critical Rules

- **Always present analysis and plan to the user before making changes**
- **Merge, don't replace** — preserve existing .csproj properties, CI jobs, hooks, .editorconfig rules
- **Use `dotnet` CLI** for all build, test, and format operations
- All hook scripts must be executable (`chmod +x`)

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — quality dimensions (roles), adaptation rules, hook architecture
- `skills/setup/analysis-checklist.md` — what to check in the target codebase
- `skills/setup/templates/` — **annotated examples** showing structural patterns (hook architecture, CI job layout). Use templates for patterns but substitute the tools chosen during research.

## Workflow

Execute these 6 phases in order.

### Phase 1: Analyze

Follow `analysis-checklist.md` systematically to examine the target project's ecosystem: .NET SDK version, target framework, solution structure, frameworks, existing tools, CI, and maturity.

**Output**: Present a structured summary to the user covering each checklist item and which quality dimensions are missing.

### Phase 2: Plan

Based on the analysis, determine what to configure. Apply adaptation rules from `methodology.md`.

**Steps**:

1. **Research and select tools** — For each of the 8 quality dimensions:
   - Check if the project already uses a tool for this role (keep it if so)
   - For unfilled roles, use WebSearch to research current best-in-class .NET tools
   - Consider: .NET version compatibility, framework support, Roslyn analyzer availability, community adoption
   - Determine configuration adjustments needed (TFM, paths, thresholds)
   - Decide whether to enable or skip this dimension (with rationale)

2. **Determine thresholds** — Based on project maturity, set thresholds for each dimension per the adaptation rules in `methodology.md` (coverage, complexity, documentation).

3. **Plan file changes** — List every file that will be created or modified:
   - `Directory.Build.props` — centralized MSBuild properties and analyzer packages
   - `.editorconfig` — formatting and analyzer severity rules
   - `.claude/hooks/` — scripts to create
   - `.claude/settings.json` — hook registrations
   - `.github/workflows/ci.yml` — CI pipeline
   - `CLAUDE.md` — project instructions

4. **Identify conflicts** — Flag any existing config that conflicts with the methodology and propose resolution.

**Output**: Present the complete plan to the user and wait for approval before proceeding. Ask about optional items (auto-commit hook, architecture tests).

### Phase 3: Configure

Apply the approved plan. Read each template in `templates/` for the structural pattern, substitute the researched tool commands, and write to the target project.

**Files to create/update** (read corresponding template for each):

1. **Directory.Build.props** — Centralized analyzer packages, Nullable, AnalysisLevel, TreatWarningsAsErrors. Merge into existing if present.
2. **.editorconfig** — C# formatting rules, naming conventions, analyzer severity. Merge into existing if present.
3. **Hook scripts** (`.claude/hooks/`) — `quality-gate.sh`, `per-edit-fix.sh`, `session-start.sh`, optionally `auto-commit.sh`. Follow the run_check/fail pattern, write tool-specific hints. Make executable.
4. **`.claude/settings.json`** — Hook registrations with correct matchers and timeouts. The correct format for settings.json hooks:
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Edit|Write",
           "hooks": [
             {
               "type": "command",
               "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/per-edit-fix.sh",
               "timeout": 60
             }
           ]
         }
       ],
       "Stop": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/quality-gate.sh",
               "timeout": 120
             }
           ]
         }
       ],
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/session-start.sh",
               "timeout": 30
             }
           ]
         }
       ]
     }
   }
   ```
   **Important matcher rules**:
   - `PostToolUse` and `PreToolUse` support matchers that filter on tool name (regex): `"Edit|Write"`, `"Bash"`, `"mcp__.*"`
   - `Stop`, `SessionStart`, `UserPromptSubmit`, `TeammateIdle`, `TaskCompleted` do **NOT** support matchers — they always fire on every occurrence. Do not add a `matcher` field to these events.
   - Matchers are case-sensitive: `Edit|Write` not `edit|write`
5. **CI pipeline** — One job per enabled dimension. Merge into existing pipeline if present.
6. **CLAUDE.md** — Create from template or append methodology reference to existing.

Then restore NuGet packages and verify the build.

### Phase 4: Review

Spawn a **reviewer subagent** to audit the generated configuration against the methodology.

**Why a subagent**: The setup skill has cognitive momentum from making decisions. A fresh agent reading the methodology and output with no prior context catches inconsistencies the setup skill is blind to.

**How to spawn**: Use the Task tool with `subagent_type: "general-purpose"`. Read `references/reviewer-prompt.md` for the full prompt template — it covers 9 review criteria including dimension coverage, fail-fast compliance, hook output format, path consistency, and threshold matching.

**After review**: Fix any FAIL items. Re-spawn the reviewer if significant changes were made. Proceed to Verify only when the review is clean.

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

**Output**: Structured summary covering:
- Configured dimensions (which roles filled, which tools chosen, thresholds)
- Files created/modified
- Quality gate results (passing checks, pre-existing issues)
- Next steps for the user

## Troubleshooting

**Quality gate fails immediately after setup**:
- Distinguish pre-existing issues (code gaps) from configuration issues (bad config). Fix config issues. Report pre-existing issues as next steps for the user.

**Solution file not found**:
- Check for `.sln` files. If none exist, look for `.csproj` files directly. Ask the user about their build structure.

**Hook timeout**:
- Increase timeout in `.claude/settings.json`. Quality gate may need 120s+ for large solutions.

**Build restore fails**:
- Check for custom NuGet feeds in `nuget.config`. Ensure authentication is configured for private feeds.
