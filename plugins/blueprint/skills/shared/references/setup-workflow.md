# Setup Workflow

The setup skill follows a 6-phase workflow. Each technology-specific setup SKILL.md provides the tech-specific details (tool names, config files, detection signals) while referencing this shared workflow structure.

---

## Phase 1: Analyze

Follow the technology-specific `analysis-checklist.md` systematically to examine the target project's ecosystem: language version, project structure, frameworks, existing tools, CI, and maturity.

**Output**: Present a structured summary to the user covering each checklist item and which quality dimensions are missing.

---

## Phase 2: Plan

Based on the analysis, determine what to configure. Apply adaptation rules from the technology-specific `methodology.md`.

**Steps**:

1. **Research and select tools** — For each of the 9 quality dimensions:
   - Check if the project already uses a tool for this role (keep it if so)
   - For unfilled roles, use WebSearch to research current best-in-class tools
   - Consider: language version compatibility, framework support, speed, community adoption
   - Determine configuration adjustments needed (paths, thresholds)
   - Decide whether to enable or skip this dimension (with rationale)

2. **Determine thresholds** — Based on project maturity, set thresholds for each dimension per the adaptation rules in the methodology.

3. **Plan file changes** — List every file that will be created or modified:
   - Tool configuration files (technology-specific)
   - `.claude/hooks/` — scripts to create
   - `.claude/settings.json` — hook registrations
   - `.github/workflows/ci.yml` — CI pipeline
   - `CLAUDE.md` — project instructions

4. **Identify conflicts** — Flag any existing config that conflicts with the methodology and propose resolution.

**Output**: Present the complete plan to the user and wait for approval before proceeding. Ask about optional items (auto-commit hook, etc.).

---

## Phase 3: Configure

Apply the approved plan. Read each template in `templates/` for the structural pattern, substitute the researched tool commands, and write to the target project.

**Common files to create/update** (read corresponding template for each):

1. **Tool config files** — Technology-specific configuration files. Merge into existing if present.
2. **Hook scripts** (`.claude/hooks/`) — `quality-gate.sh`, `per-edit-fix.sh`, `session-start.sh`, optionally `auto-commit.sh`. **Every hook must follow these two principles**:
   - **Fail-fast**: Stop at the first failure (exit 2). Do NOT collect multiple errors. This applies to ALL blocking hooks, including per-edit-fix.sh when it has multiple tools.
   - **Descriptive output**: Every failure must include 4 parts in stderr: (1) what failed — check name and command, (2) tool output — raw errors with file paths and line numbers, (3) diagnostic hint — tool-specific instruction on how to investigate and fix, (4) action directive — tells Claude to fix immediately and states whether the hook re-runs automatically or must be re-run manually.
   - Follow the `fail()` pattern from methodology-framework.md templates. Write tool-specific hints.
   - Make executable (`chmod +x`).
3. **`.claude/settings.json`** — Hook registrations. See `methodology-framework.md` for the correct format and matcher rules.
4. **CI pipeline** — One job per enabled dimension. Merge into existing pipeline if present.
5. **CLAUDE.md** — Create from template or append methodology reference to existing.
6. **semver-check.sh** (`.claude/hooks/`) — PostToolUse/Bash hook for version bump enforcement. Only created when Dimension 9 is activated at level 3. Must follow the same fail-fast and descriptive output principles. Make executable.

Then install dev dependencies using the project's package manager.

---

## Phase 4: Review

Spawn a **reviewer subagent** to audit the generated configuration against the methodology.

**Why a subagent**: The setup skill has cognitive momentum from making decisions. A fresh agent reading the methodology and output with no prior context catches inconsistencies the setup skill is blind to.

**How to spawn**: Use the Task tool with `subagent_type: "general-purpose"`. Read the technology-specific `references/reviewer-prompt.md` for the full prompt template — it covers review criteria including dimension coverage, fail-fast compliance, hook output format, path consistency, and threshold matching.

**After review**: Fix any FAIL items. Re-spawn the reviewer if significant changes were made. Proceed to Verify only when the review is clean.

---

## Phase 5: Verify

Run the quality gate to confirm everything works.

**Steps**:

1. Run the newly created quality gate script: `.claude/hooks/quality-gate.sh`
2. Collect pass/fail results for each check
3. For any failures, determine if they are:
   - **Pre-existing issues** — code quality gaps that exist before the methodology was applied
   - **Configuration issues** — problems with the generated config that need fixing

**Output**: Report results to the user, distinguishing pre-existing issues from config problems. Fix any config problems. For pre-existing issues, suggest next steps.

---

## Phase 6: Report

Summarize everything that was done.

**Output**: Structured summary covering:
- Configured dimensions (which roles filled, which tools chosen, thresholds)
- Files created/modified
- Quality gate results (passing checks, pre-existing issues)
- Next steps for the user

---

## Troubleshooting

**Quality gate fails immediately after setup**:
- Distinguish pre-existing issues (code gaps) from configuration issues (bad config). Fix config issues. Report pre-existing issues as next steps for the user.

**Hook timeout**:
- Increase timeout in `.claude/settings.json`. Quality gate may need 120s+ for large projects.
