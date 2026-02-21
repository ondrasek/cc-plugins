# Phase 5: Supporting Skills

## Status: Complete

## Goal

Create audit, update, and explain skills to complete the plugin's skill suite.

## Deliverable

Three additional skills that complement the setup skill, providing ongoing value.

## Files to Create

### Audit Skill

- **`skills/audit/SKILL.md`** — gap analysis vs methodology
  - Reads the project's current configuration
  - Compares against the full methodology
  - Reports gaps, outdated configs, missing checks
  - Suggests specific remediation steps
  - Does NOT make changes (read-only)

### Update Skill

- **`skills/update/SKILL.md`** — incremental updates to latest methodology
  - Detects what version of the methodology was last applied
  - Shows diff between current and latest methodology
  - Applies incremental updates (new tools, updated thresholds, etc.)
  - Preserves project-specific customizations
  - Interactive: presents changes for approval before applying

### Explain Skill

- **`skills/explain/SKILL.md`** — read-only Q&A about the methodology
  - Answers questions about why specific tools are included
  - Explains quality dimensions and their rationale
  - Describes how thresholds were chosen
  - Provides context for specific checks
  - Purely informational, no file changes

## Invocation

- `/python-blueprint:audit` — run gap analysis
- `/python-blueprint:update` — apply methodology updates
- `/python-blueprint:explain` — ask about the methodology

## Verification

- Each skill can be invoked via its command
- Audit correctly identifies gaps in a partially-configured project
- Update correctly applies incremental changes
- Explain provides accurate, helpful answers about the methodology
