---
name: audit
description: Read-only gap analysis comparing a Neovim Lua plugin's current quality setup against the 9-dimension methodology. Use when user says "audit quality", "check coverage gaps", "what's missing", or wants to see how their plugin measures up before running setup.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Audit

Read-only — does not modify any files.

## Context Files

Read these files from the plugin before starting:

- `skills/setup/methodology.md` — the 9 quality dimensions (roles) to audit against
- `skills/setup/analysis-checklist.md` — what to check in the target codebase

## Workflow

### 1. Analyze Current State

Follow the same analysis steps as the setup skill (Phase 1 of `skills/setup/SKILL.md`):
- Detect project structure (lua/, plugin/, tests/, doc/)
- Inventory existing tool configurations (selene.toml, .stylua.toml, .luacov, .luarc.json)
- Detect test framework (plenary, mini.test, busted)
- Check for existing hooks in `.claude/settings.json`
- Check for CI pipeline
- Check for installed tools (selene, stylua, lizard)

### 2. Compare Against Methodology

For each of the 9 quality dimensions from `methodology.md`, check whether the role is filled by any tool:

1. **Testing & Coverage** — Is there a test suite? Is coverage measured? What's the threshold?
2. **Linting & Formatting** — Is selene configured? Is stylua configured? Is auto-format on edit?
3. **Type Safety** — Is lua-language-server configured? Are LuaCATS annotations present?
4. **Security Analysis** — Are dangerous patterns checked? Is selene covering security-relevant lints?
5. **Code Complexity** — Is lizard or another complexity checker configured? What threshold?
6. **Dead Code & Modernization** — Are unused variable lints enabled? Are deprecated APIs flagged?
7. **Documentation** — Does doc/ exist? Are vimdoc help files present? Is a doc generator configured?
8. **Architecture** — Are plugin/ files small entry points? Is lua/ properly structured?
9. **Version Discipline** — Is there a version field? Is it semver 2.0? Is bump enforcement configured?

### 3. Check Hook Coverage

Verify Claude Code hooks are configured for each hook event from `methodology.md`:
- SessionStart → plugin structure and tool checks (non-blocking)
- PostToolUse (Edit|Write) → per-edit auto-format (StyLua)
- Stop → quality gate (all enabled dimensions)
- Stop → auto-commit (optional)
- PostToolUse (Bash) → semver bump enforcement (blocking, only if Dimension 9 active)

### 4. Check CI Coverage

Verify CI pipeline has a job for each enabled dimension:
- test (Neovim version matrix + coverage)
- lint (selene + stylua)
- typecheck (lua-language-server, if enabled)
- version (semver format check)

### 5. Report

Present findings in a structured format:

```
## Audit Results

### Dimension Coverage
| Dimension | Status | Tools | Notes |
|-----------|--------|-------|-------|
| Testing & Coverage | Configured | plenary.nvim | No coverage measurement |
| Linting & Formatting | Partial | stylua | selene not configured |
| Type Safety | Missing | — | No .luarc.json or LuaCATS annotations |
| Security Analysis | Default | — | No explicit security checks |
| Code Complexity | Missing | — | No complexity measurement |
| Dead Code | Partial | selene | Only if selene is configured |
| Documentation | Missing | — | No doc/ directory |
| Architecture | Default | — | No plugin/ size enforcement |
| Version Discipline | Missing | — | No version validation configured |

### Hook Coverage
- [x] PostToolUse (per-edit fix)
- [ ] Stop (quality gate) — not configured
- [ ] Stop (auto-commit) — not configured
- [ ] SessionStart (structure check) — not configured

### CI Coverage
- [x] test
- [ ] lint — missing
- [ ] typecheck — missing

### Recommendations
1. Run `/nvim-lua-blueprint:setup` to configure missing dimensions
2. Add selene.toml with std = "vim" for Neovim-aware linting
3. Create doc/ directory with vimdoc help files
4. Add complexity checking with lizard
```

## Important Notes

- Compare against methodology roles, not specific tools — any tool filling the role counts
- Note where project-specific thresholds may be appropriate
- Flag outdated tools that have been superseded by better alternatives
- Report both missing dimensions and misconfigured existing tools

## Troubleshooting

**No lua/ directory found**:
- The project may not be a Neovim plugin. Suggest using the appropriate blueprint plugin instead.

**Hooks configured but methodology.md not found**:
- The project may have been configured manually without the plugin. Audit the hooks against the methodology principles anyway.
