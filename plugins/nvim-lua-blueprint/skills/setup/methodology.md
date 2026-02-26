# Neovim Lua Plugin Quality Methodology

This document defines the quality methodology applied by the `nvim-lua-blueprint` plugin. It is organized into 9 quality dimensions, each defining a **role** (what needs to happen) rather than prescribing specific tools.

The setup skill reads this document to understand what to apply, then researches current best-in-class tools to fill each role.

---

## Principles

1. **Fail fast, fix fast** — Quality checks run as Claude Code hooks. Failures block the agent and feed back for automatic fixing (exit code 2).
2. **Ordered by speed** — Checks run fastest-first so common failures surface quickly.
3. **Opinionated defaults, flexible adaptation** — Defaults reflect production-grade Neovim plugin standards. Every dimension can be relaxed for early-stage or experimental plugins.
4. **Roles, not tools** — The methodology defines *what* to check, not *which tool*. The setup skill researches current tools to fill each role, considering the project's ecosystem.
5. **Incremental adoption** — Projects can adopt dimensions one at a time. The audit skill tracks which dimensions are active.

---

## Dimension 1: Testing & Coverage

**Role**: Verify that code changes are backed by tests. Measure and enforce test coverage thresholds.

**What the tool must do**:
- Discover and run tests (unit, functional, integration)
- Stop on first failure (fail-fast mode)
- Measure line coverage against a threshold
- Report uncovered lines
- Support headless Neovim execution for tests

**Default thresholds**:
- Minimum coverage: 75%
- Test location: `tests/` directory

**Test framework detection** (check in order):
1. **plenary.nvim** — `PlenaryBustedDirectory` or `PlenaryBustedFile` in test files, `plenary.nvim` in dependencies
2. **mini.test** — `MiniTest` references, `mini.nvim` or `mini.test` in dependencies
3. **busted** — `.busted` config file, `busted` in rockspec dependencies, `describe`/`it` without plenary imports

**Invocation patterns**:
- plenary: `nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"`
- mini.test: `nvim --headless -u tests/minimal_init.lua -c "lua MiniTest.run()"`
- busted: `busted tests/`

**Coverage** (optional, lower confidence):
- luacov can measure coverage but integration with headless Neovim is less mature
- Default threshold 75% (vs 85-95% for other ecosystems) acknowledges this limitation
- Setup skill should check if luacov is viable for the project before enabling

**Adaptation**:
- New plugin (< 500 LOC): 50%
- Legacy plugin adopting methodology: start at current coverage, increase incrementally
- Library plugin (used by other plugins): raise to 80%
- Plugin without tests: create `tests/minimal_init.lua` and starter test

**Quality gate**: Run tests (fail-fast), then run coverage check against threshold (if enabled).

**CI job**: `test` — run tests with Neovim matrix (`stable`, `nightly`), upload coverage on PRs.

---

## Dimension 2: Linting & Formatting

**Role**: Enforce consistent code style. Detect common bugs, anti-patterns, and Neovim API misuse.

**What the tools must do**:
- Lint: check for unused variables, shadowing, incorrect Neovim API usage, deprecated patterns
- Format: enforce consistent whitespace, indentation, quote style, line width

**Default tools**:
- Linter: Selene — Lua-specific, supports Neovim globals via custom std library
- Formatter: StyLua — fast, opinionated, configurable

**Default configuration**:
- `selene.toml` with `std = "vim"` and accompanying `vim.toml` for Neovim globals
- `.stylua.toml` with project-appropriate settings
- Auto-format on every file edit (per-edit hook)
- Selene has NO `--fix` flag — issues must be fixed manually by Claude

**Quality gate**: `selene lua/` (deny warnings) + `stylua --check lua/`.

**Per-edit hook**: Auto-format on every `.lua` file edit via StyLua. Report unfixable issues back to Claude (exit 2).

**CI job**: `lint` — selene check + stylua check.

---

## Dimension 3: Type Safety

**Role**: Leverage LuaCATS type annotations checked by lua-language-server in batch mode.

**What the tools must do**:
- Run lua-language-server `--check` mode for batch type analysis
- Report type errors, missing fields, incorrect function signatures
- Support Neovim API type definitions

**Default configuration**:
- `.luarc.json` with Neovim runtime paths and diagnostics settings
- LuaCATS annotations in source files (`---@param`, `---@return`, `---@class`, etc.)
- `lua-language-server --check` for CI and quality gate

**Adaptation**:
- New plugin with no type annotations: skip or warn-only; add incrementally
- Plugin with existing annotations: enable strict checking
- Plugin using vim.api heavily: ensure Neovim type stubs are configured

**Quality gate**: `lua-language-server --check lua/` (report errors).

**CI job**: `typecheck` — lua-language-server in check mode.

---

## Dimension 4: Security Analysis

**Role**: Detect dangerous patterns in Lua source code. **This dimension is limited in the Lua ecosystem** — there is no equivalent of bandit (Python) or cargo-audit (Rust).

**What the tool must do**:
- Detect dangerous function calls: `os.execute`, `io.popen`, `loadstring`, `load` (with string arg), `dofile` on user input
- Flag `vim.fn.system` and `vim.fn.systemlist` with unsanitized user input
- Detect hardcoded paths and credentials

**Implementation**: Use selene custom rules or grep-based checks. This dimension shares a selene pass with Dimension 2.

**Default configuration**:
- Selene rules for dangerous patterns (where available)
- Grep-based fallback for patterns selene doesn't cover
- Mark findings as warnings, not errors (low false-positive confidence)

**Adaptation**:
- Plugin that legitimately uses `os.execute` (e.g., CLI wrappers): allowlist specific patterns
- Plugin with no external process calls: skip this dimension

**Quality gate**: Grep-based check for dangerous patterns in `lua/` directory.

**CI job**: Included in `lint` job (selene covers most patterns).

---

## Dimension 5: Code Complexity

**Role**: Enforce measurable cyclomatic complexity limits to keep functions testable and maintainable.

**What the tool must do**:
- Measure cyclomatic complexity per function
- Fail when functions exceed threshold
- Report which functions are too complex

**Default tool**: Lizard — language-agnostic, supports Lua.

**Default thresholds**:
- Maximum cyclomatic complexity: 10 (per function)
- Maximum function length: 50 lines

**Adaptation**:
- Early-stage plugin: accept complexity ≤ 15 temporarily
- Legacy codebase: start at current max, tighten over time

**Quality gate**: `lizard lua/ --CCN ${COMPLEXITY_THRESHOLD} --warnings_only`.

---

## Dimension 6: Dead Code & Modernization

**Role**: Detect unused variables, functions, and imports. Identify deprecated Neovim API usage.

**What the tools must do**:
- Dead code: detect unused locals, unreachable code, unused function parameters
- Modernization: flag deprecated `vim.api` calls, suggest modern replacements

**Implementation**: Selene handles unused variable/import detection. This dimension overlaps with Dimension 2 — a single selene pass covers both.

**Default configuration**:
- Selene `unused_variable` lint at warn level
- Selene `shadowing` lint enabled
- Deprecation checks via lua-language-server diagnostics (overlaps Dimension 3)

**Quality gate**: Covered by the selene pass in Dimension 2. No separate check needed.

---

## Dimension 7: Documentation

**Role**: Ensure the plugin has vimdoc help files and they stay in sync with the source.

**What the tools must do**:
- Verify `doc/` directory exists with `*.txt` help files
- Check doc generation staleness (if using a doc generator)
- Verify help tags are generated (`doc/tags`)

**Doc generator detection**:
- `lemmy-help` — annotations in source, `lemmy-help` in dependencies or Makefile
- `mini.doc` — `MiniDoc` references, `mini.doc` in dependencies
- `tree-sitter-vimdoc` — vimdoc parsed from source
- Manual — hand-written vimdoc (no generator)

**Default configuration**:
- Verify `doc/*.txt` exists
- If doc generator detected, verify generated docs match source (staleness check)
- If no `doc/` directory, flag as warning and suggest creating one

**Adaptation**:
- Utility plugin (internal): documentation optional, warn only
- Published plugin: documentation required
- Plugin with complex API: recommend doc generator

**Quality gate**: Check `doc/` directory exists and contains `*.txt` files.

**CI job**: Doc staleness check (if generator detected).

---

## Dimension 8: Architecture & Plugin Structure

**Role**: Enforce Neovim plugin structure conventions. Keep `plugin/` directory minimal, `lua/` for logic.

**What the tools must do**:
- Verify `plugin/*.lua` files are small (entry points only — `require` calls and command/autocmd registration)
- Verify main logic lives in `lua/<plugin_name>/` with proper module structure
- Check `require` path conventions match directory structure
- Detect circular requires

**Progressive activation**:

Architecture enforcement in Neovim plugins is about convention, not compiler enforcement:

1. **No explicit boundaries defined**: the gate checks `plugin/` file sizes and `lua/` directory existence. Most projects start here.
2. **Size issue detected** → gate fails with a hint telling Claude to move logic from `plugin/` to `lua/`.
3. **Mature plugin**: verify module organization under `lua/<plugin_name>/`.

**Default thresholds**:
- `plugin/*.lua` files: maximum 30 lines each (entry points only)
- Main logic must be in `lua/` directory

**Adaptation**:
- Simple plugin (single file): relax `plugin/` size limit
- Plugin with `after/`, `ftplugin/`, `colors/`: verify structure but don't enforce size
- Plugin with no `plugin/` directory (lazy-loaded only): skip this check

**Quality gate**: Check `plugin/` file sizes + `lua/` directory existence.

**Session start hook**: `plugin/` size check, `doc/` existence, `selene.toml` check.

---

## Dimension 9: Version Discipline

**Role**: Enforce semver 2.0 on the project's version string. Detect missing version bumps when source code changes are committed.

**What the tools must do**:
- Validate the project's version string follows semver 2.0 format (MAJOR.MINOR.PATCH with optional pre-release and build metadata)
- On commit, compare the version at the branch base vs HEAD — block if source files changed but the version did not

**Progressive activation**:

Version discipline is never configured speculatively. The quality gate drives its introduction:

1. **No version field detected**: the dimension is skipped entirely. Internal plugins start here.
2. **Version field exists, not published**: format validation only (quality gate). Catches typos and non-semver strings.
3. **Version field + published (luarocks/rockspec)**: both format validation (quality gate) AND bump enforcement (PostToolUse/Bash hook on `git commit`).

Detection signals for Neovim Lua plugins:
- **Version in rockspec**: `*-scm-1.rockspec` or `*-dev-1.rockspec` with `version` field
- **Version in module**: `M.version` or `M._VERSION` in main module file
- **Version in plugin table**: `config.version` or similar in setup/config module
- **Published**: presence of rockspec without `scm` or `dev` suffix indicates release intent

**Default configuration**:
- Semver 2.0 regex validation in the quality gate
- PostToolUse/Bash hook (`semver-check.sh`) that fires only on `git commit`

**Adaptation**:
- Plugin with rockspec: check rockspec version field
- Plugin with `M.version`: check module version
- Plugin without any version: skip entirely
- Pre-1.0 plugin: no special treatment — semver pre-release tags handle instability

**Quality gate**: Validate version string matches semver 2.0 regex.

**PostToolUse/Bash hook**: On `git commit`, compare version at merge-base vs HEAD. Block if source dirs changed but version is unchanged.

**CI job**: `version` — extract and validate version string format.

---

## Hook Architecture

The methodology uses four hook types:

| Hook Event | Script | Behavior | Blocking |
|-----------|--------|----------|----------|
| **SessionStart** | `session-start.sh` | `plugin/` size check, `doc/` existence, `selene.toml` presence | No (warnings only) |
| **PostToolUse** (Edit\|Write) | `per-edit-fix.sh` | StyLua auto-format on each `.lua` file edit | Yes (exit 2 for unfixable) |
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

### Output Examples

**Good** — a quality gate failure for selene:
```
QUALITY GATE FAILED [selene]:
Command: selene lua/

error[unused_variable]: x is assigned a value, but never used
  ┌─ lua/myplugin/init.lua:15:11
  │
15 │     local x = vim.fn.expand("%")
  │           ^ `x` is never used

Hint: Read the file at the reported line number. Remove the unused variable
or prefix it with an underscore (_x) if it's intentionally unused. Run
'selene lua/myplugin/' to re-check a single module after fixing.

ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or
explain — read the failing file, edit the source code to resolve it,
and the quality gate will re-run automatically.
```

**Good** — a per-edit hook reporting a format issue:
```
Per-edit check found issues in lua/myplugin/init.lua:
FORMAT (stylua):
Could not format lua/myplugin/init.lua: syntax error at line 42
```

**Bad** — a wall of text with multiple failures (do NOT do this):
```
ERROR: 47 issues found
warn: unused variable `x`
warn: unused variable `y`
warn: shadowing variable `config`
... (43 more lines)
```

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
- Tell Claude **how to re-check** a single module after fixing (avoids re-running the full gate)
- Tell Claude **what to fix** (edit source code, not the test, unless the test is wrong)
- Are **specific to the tool** (not generic "fix the error" advice)

Example hints:
```
[test]          "Read the failing test and the source it tests. Run the
                 individual test to see the full output. Fix the source code,
                 not the test, unless the test itself is wrong."

[selene]        "Read the file at the reported line. Selene errors include the
                 lint rule name. Fix the issue or add a -- selene: allow(rule)
                 comment if the lint is a false positive. Run 'selene lua/module/'
                 to re-check a single module."

[stylua]        "Run 'stylua lua/' to auto-fix all formatting issues."
```

---

## Neovim Lua-Specific Patterns

### Lua Version

Neovim embeds LuaJIT, which implements Lua 5.1 with select 5.2 features. Always configure tools for LuaJIT/Lua 5.1:
- `selene.toml`: `std = "vim"` (custom Neovim std library)
- `.luarc.json`: `runtime.version = "LuaJIT"`
- `.stylua.toml`: `lua_version = "luajit"`

### Plugin Directory Structure

Standard Neovim plugin layout:
```
plugin/         — Entry points (autoload on startup)
lua/            — Main logic (loaded on demand via require)
  <name>/       — Plugin namespace
    init.lua    — Module root
    config.lua  — Configuration/setup
    *.lua       — Feature modules
tests/          — Test files
  minimal_init.lua — Minimal Neovim config for testing
doc/            — Help documentation (vimdoc format)
after/          — After-plugin overrides (optional)
ftplugin/       — Filetype-specific (optional)
colors/         — Colorscheme definitions (optional)
```

### Config Files

Neovim Lua plugins use distributed config files (no single central config):
- `selene.toml` + `vim.toml` — Selene linter configuration
- `.stylua.toml` — StyLua formatter configuration
- `.luacov` — luacov coverage configuration
- `.luarc.json` — lua-language-server configuration
- `*.rockspec` — LuaRocks package specification
- `Makefile` — Common build/test targets

### Neovim Global Access

Neovim plugins extensively use global `vim.*` APIs:
- `vim.api.*` — Neovim API functions
- `vim.fn.*` — Vimscript functions
- `vim.opt.*` — Option management
- `vim.keymap.*` — Keymap management
- `vim.treesitter.*` — Treesitter integration
- `vim.lsp.*` — LSP client
- `vim.diagnostic.*` — Diagnostics

Selene needs a custom std library (`vim.toml`) that defines these globals to avoid false "undefined variable" warnings.

---

## CI Pipeline Structure

The CI pipeline runs a subset of the quality gate as parallel jobs:

| Job | Dimension | Purpose |
|-----|-----------|---------|
| `test` | Testing & Coverage | Run tests with Neovim matrix, upload coverage |
| `lint` | Linting & Formatting | Selene + StyLua check |
| `typecheck` | Type Safety | lua-language-server batch check |
| `version` | Version Discipline | Verify semver format |

Jobs run on `push` to main and on pull requests to main. The test job runs against multiple Neovim versions (stable + nightly).

---

## Tool Research

When the setup skill fills each role, it should:

1. **Check what the project already uses** — respect existing tool choices
2. **Research current best tools** (via WebSearch) for any unfilled roles, considering:
   - Compatibility with LuaJIT/Lua 5.1
   - Neovim-specific support (globals, API awareness)
   - Community adoption in the Neovim plugin ecosystem
   - Speed (quality gate runs on every stop, so tools must be fast)
   - Standalone binary availability (no complex dependency chains)
3. **Present tool choices to the user** with rationale before configuring

---

## Claude Code Hygiene

These checks target the Claude Code development environment itself — project instructions, hooks, and agent configuration. Unlike the 9 code quality dimensions, these ensure the AI-assisted workflow is correctly set up and efficient.

---

### CC1: Project Instructions (CLAUDE.md)

**Role**: Keep CLAUDE.md concise, actionable, and focused so Claude follows every instruction reliably.

**What to check**:
- Total size ≤ 2500 tokens (including content pulled in via `@path` imports and all rule files under `.claude/rules/`)
- No self-evident instructions ("write clean code", "follow best practices")
- Includes required operational content: test commands, non-obvious conventions, environment quirks

**Default threshold**: 2500 tokens

---

### CC2: Hook & Script Hygiene

**Role**: Ensure Claude Code hooks are correctly configured so the feedback loop works reliably.

**What to check**:
- All registered hook scripts exist and are executable (`chmod +x`)
- Exit codes follow convention: 0 (pass), 2 (fail with feedback). Never exit 1 for check failures
- Matchers are case-sensitive correct (`Edit|Write` not `edit|write`, `Bash` not `bash`)
- Scripts use `${CLAUDE_PROJECT_DIR}` or `${CLAUDE_PLUGIN_ROOT}` for paths
- Timeouts are appropriate: quality gate ≥ 120s, per-edit ≤ 30s

---

### CC3: Context Efficiency

**Role**: Keep skills, prompts, and configuration right-sized to preserve Claude's context window.

**What to check**:
- Skill SKILL.md files ≤ 500 lines
- Subagent prompts are scoped to a single responsibility
- Heavy reference material uses progressive disclosure: metadata → SKILL.md body → `references/` subdirectory
