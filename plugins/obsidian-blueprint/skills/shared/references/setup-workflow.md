# Setup Workflow

The setup skill follows a 6-phase workflow. The vault-specific setup SKILL.md provides vault-specific details (tool names, config files, detection signals) while referencing this shared workflow structure.

---

## Phase 1: Analyze

Follow the vault-specific `analysis-checklist.md` systematically to examine the target vault's ecosystem: folder structure, frontmatter conventions, templates, community plugins, daily notes, existing .gitignore, and maturity.

**Output**: Present a structured summary to the user covering each checklist item and which quality dimensions are missing.

---

## Phase 2: Plan

Based on the analysis, determine what to configure. Apply adaptation rules from the vault-specific `methodology.md`.

**Steps**:

1. **Research and select tools** — For each of the 7 quality dimensions:
   - Check if the vault already uses a tool for this role (keep it if so)
   - For unfilled roles, use WebSearch to research current best-in-class tools
   - Consider: Node.js compatibility, Obsidian plugin ecosystem, speed, community adoption
   - Determine configuration adjustments needed (paths, thresholds, ignore patterns)
   - Decide whether to enable or skip this dimension (with rationale)

2. **Research GitHub workflow patterns** — From `workflow-catalog.md`:
   - Analyze vault structure to determine which workflow categories fit (daily notes, calendar sync, link validation, attachment optimization)
   - Research `anthropics/claude-code-action` capabilities for AI-powered review workflows
   - Propose workflows tailored to the vault's needs

3. **Determine thresholds** — Based on vault maturity, set thresholds for each dimension per the adaptation rules in the methodology.

4. **Plan file changes** — List every file that will be created or modified:
   - Tool configuration files (linter configs, spelling dictionaries)
   - `.claude/hooks/` — scripts to create
   - `.claude/settings.json` — hook registrations
   - `.github/workflows/` — GitHub Actions workflows (from workflow catalog)
   - `.gitignore` — vault-specific ignore rules
   - `CLAUDE.md` — project instructions

5. **Identify conflicts** — Flag any existing config that conflicts with the methodology and propose resolution.

6. **Recommend companion plugin** — Suggest `kepano/obsidian-skills` as a companion plugin for Obsidian-specific Claude Code skills, if not already installed.

**Output**: Present the complete plan to the user and wait for approval before proceeding. Include: dimension configuration, hook scripts, CLAUDE.md content, .gitignore updates, and proposed GitHub Actions workflows.

---

## Phase 3: Configure

Apply the approved plan. Read each template in `templates/` for the structural pattern, substitute the researched tool commands, and write to the target vault.

**Common files to create/update** (read corresponding template for each):

1. **Tool config files** — Spelling dictionaries, linter configs, frontmatter schemas. Merge into existing if present.
2. **Hook scripts** (`.claude/hooks/`) — `quality-gate.sh`, `per-edit-fix.sh`, `session-start.sh`. Follow the run_check/fail pattern, write tool-specific hints. Make executable.
3. **`.claude/settings.json`** — Hook registrations. See `methodology-framework.md` for the correct format and matcher rules.
4. **GitHub Actions workflows** (`.github/workflows/`) — One workflow per approved catalog item. Use matrix strategies where appropriate.
5. **`.gitignore`** — Vault-specific ignore rules (workspace files, plugin caches, OS artifacts).
6. **`CLAUDE.md`** — Create from template or append methodology reference to existing.

Then install any required CLI tools using the appropriate package manager.

---

## Phase 4: Review

Spawn a **reviewer subagent** to audit the generated configuration against the methodology.

**Why a subagent**: The setup skill has cognitive momentum from making decisions. A fresh agent reading the methodology and output with no prior context catches inconsistencies the setup skill is blind to.

**How to spawn**: Use the Task tool with `subagent_type: "general-purpose"`. Read the vault-specific `references/reviewer-prompt.md` for the full prompt template — it covers review criteria including dimension coverage, fail-fast compliance, hook output format, path consistency, and threshold matching.

**After review**: Fix any FAIL items. Re-spawn the reviewer if significant changes were made. Proceed to Verify only when the review is clean.

---

## Phase 5: Verify

Run the quality gate to confirm everything works.

**Steps**:

1. Run the newly created quality gate script: `.claude/hooks/quality-gate.sh`
2. Collect pass/fail results for each check
3. For any failures, determine if they are:
   - **Pre-existing issues** — vault quality gaps that exist before the methodology was applied (e.g., broken links, missing frontmatter)
   - **Configuration issues** — problems with the generated config that need fixing

**Output**: Report results to the user, distinguishing pre-existing issues from config problems. Fix any config problems. For pre-existing issues, suggest next steps.

---

## Phase 6: Report

Summarize everything that was done.

**Output**: Structured summary covering:
- Configured dimensions (which roles filled, which tools chosen, thresholds)
- Files created/modified
- GitHub Actions workflows created (if any)
- Quality gate results (passing checks, pre-existing issues)
- Companion plugin recommendations
- Next steps for the user

---

## Troubleshooting

**Quality gate fails immediately after setup**:
- Distinguish pre-existing issues (vault quality gaps) from configuration issues (bad config). Fix config issues. Report pre-existing issues as next steps for the user.

**Hook timeout**:
- Increase timeout in `.claude/settings.json`. Quality gate may need 120s+ for large vaults with many notes.

**Tool not found**:
- Ensure CLI tools are installed globally or in the project's node_modules. Check that PATH includes the tool location.
