# Phase 6: End-to-End Testing + Polish

## Status: Planned

## Goal

Test the complete plugin on fresh and existing projects, fix issues, and prepare for release.

## Deliverable

A verified, documented, release-ready plugin.

## Test Scenarios

### Fresh Project
1. Create a new Python project with `uv init`
2. Install the plugin
3. Run `/python-blueprint:setup`
4. Verify all hooks, CI, and quality gate work
5. Make changes and verify per-edit hook triggers
6. Run `/python-blueprint:audit` — should show clean results

### Existing Project (minimal tooling)
1. Use a project with only pytest and basic ruff
2. Run `/python-blueprint:setup`
3. Verify it detects existing tools and builds on them
4. Verify no conflicts with existing configs

### Existing Project (full tooling)
1. Use a project with extensive existing quality tooling
2. Run `/python-blueprint:setup`
3. Verify it respects existing configs
4. Verify it only adds missing pieces

### Framework-Specific
1. Test with a Django project
2. Test with a FastAPI project
3. Test with a CLI tool project
4. Verify framework-specific adaptations

## Polish Tasks

- Review all skill prompts for clarity and completeness
- Ensure consistent terminology across all documentation
- Add version tracking to methodology (for update skill)
- Review hook performance (timeout tuning)
- Final README.md pass
- Tag v0.1.0 release

## Verification

- All test scenarios pass
- Plugin installs cleanly on a fresh machine
- No hardcoded paths or assumptions
- Documentation is complete and accurate
- Plugin.json version matches release tag
