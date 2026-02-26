# Analysis Checklist

This checklist defines what the setup skill must analyze in a target codebase before applying the methodology. Each section feeds into tool selection, configuration, and threshold decisions.

---

## 1. Build System

**Check for**:
- [ ] `*.rockspec` file (LuaRocks package spec)
- [ ] `Makefile` with test/lint/format targets
- [ ] `flake.nix` (Nix-based development environment)
- [ ] `justfile` (just command runner)
- [ ] `Taskfile.yml` (Task runner)

**Impact**: Determines how to invoke tests and tools. Rockspec presence indicates publishing intent (affects Dimension 9).

---

## 2. Lua Version

**Check for**:
- [ ] Neovim plugin (always LuaJIT/Lua 5.1)
- [ ] `selene.toml` → existing `std` setting
- [ ] `.luarc.json` → `runtime.version`
- [ ] `.stylua.toml` → `lua_version`

**Impact**: Always LuaJIT for Neovim. Must verify all config files are consistent. Set `std = "vim"` in selene with a `vim.toml` defining Neovim globals.

---

## 3. Project Structure

**Check for**:
- [ ] `plugin/` directory (entry points loaded on startup)
- [ ] `lua/` directory (main logic, loaded on demand)
- [ ] `lua/<plugin_name>/` namespace directory
- [ ] `tests/` directory
- [ ] `tests/minimal_init.lua` (test initialization)
- [ ] `doc/` directory (vimdoc help files)
- [ ] `after/` directory (after-plugin overrides)
- [ ] `ftplugin/` directory (filetype-specific plugins)
- [ ] `colors/` directory (colorscheme definitions)
- [ ] `queries/` directory (treesitter queries)

**Impact**: Determines source paths for quality gate (`${SOURCE_DIR}`), test paths (`${TEST_DIR}`), documentation checks, and architecture enforcement.

---

## 4. Plugin Type

**Check for** (in source files and README):
- [ ] Colorscheme plugin (`colors/` directory, highlight group definitions)
- [ ] Filetype plugin (`ftplugin/`, syntax files)
- [ ] UI plugin (floating windows, statusline, telescope extensions)
- [ ] LSP plugin (language server integration, `vim.lsp.*` usage)
- [ ] Treesitter plugin (`vim.treesitter.*`, queries/)
- [ ] Utility plugin (keymaps, commands, general Neovim enhancement)
- [ ] CLI wrapper (external tool integration via `vim.fn.system`)
- [ ] Library plugin (used by other plugins, provides API)

**Impact**:
- Colorscheme: relax linting (highlight definitions are repetitive), skip complexity
- Filetype: verify ftplugin/ structure, filetype detection
- UI: test Neovim UI APIs, check floating window patterns
- LSP: verify LSP client setup, check capability handling
- Library: raise coverage threshold, require documentation, strict type checking

---

## 5. Existing Tools

**Check for standalone config files**:
- [ ] `selene.toml` — selene linter configuration
- [ ] `vim.toml` — selene Neovim globals definition
- [ ] `.stylua.toml` or `stylua.toml` — StyLua configuration
- [ ] `.luacov` — luacov coverage configuration
- [ ] `.luarc.json` — lua-language-server configuration
- [ ] `.editorconfig` — editor settings

**Impact**: Merge methodology config into existing config; don't overwrite user customizations. Respect existing tool choices and settings.

---

## 6. Test Framework

**Check for**:
- [ ] `plenary.nvim` — `PlenaryBustedDirectory`/`PlenaryBustedFile` in test files, plenary in dependencies
- [ ] `mini.test` — `MiniTest` references, mini.nvim in dependencies
- [ ] `busted` — `.busted` config, busted in rockspec test dependencies
- [ ] `vusted` — vusted wrapper for busted with Neovim runtime
- [ ] Test helper files (`tests/minimal_init.lua`, `tests/helpers/`)

**Impact**: Determines `${TEST_COMMAND}` template variable. Test framework choice affects test file structure, assertions, and CI configuration.

---

## 7. Existing CI/CD

**Check for**:
- [ ] `.github/workflows/*.yml` — GitHub Actions
- [ ] `.gitlab-ci.yml` — GitLab CI
- [ ] Neovim version matrix in CI (stable, nightly, specific versions)
- [ ] Existing test/lint jobs

**Impact**: If CI exists, merge quality checks into existing pipeline rather than overwriting. If no CI, create `.github/workflows/ci.yml`.

---

## 8. Existing Claude Code Configuration

**Check for**:
- [ ] `.claude/settings.json` — existing hooks, permissions
- [ ] `.claude/hooks/` — existing hook scripts
- [ ] `CLAUDE.md` — existing project instructions

**Impact**: Merge hooks into existing settings.json. Don't overwrite existing CLAUDE.md — append methodology reference.

---

## 9. Project Maturity Signals

**Assess**:
- [ ] Git history length (commits, age)
- [ ] Lines of code (approximate via `find lua/ -name '*.lua' | xargs wc -l`)
- [ ] Number of test files
- [ ] Existing coverage percentage (if configured)
- [ ] README quality and completeness
- [ ] Number of GitHub stars / downloads (if public)

**Impact**: Determines initial thresholds:
| Signal | Coverage | Documentation | Complexity |
|--------|----------|---------------|------------|
| New (< 500 LOC) | 50% | warn | 15 |
| Small (500–2k LOC) | 60% | warn | 12 |
| Medium (2k–10k LOC) | 75% | warn | 10 |
| Large (10k+ LOC) | 75% | warn | 10 |
| Library plugin | 80% | required | 10 |

---

## 10. Version & Packaging

**Check for**:
- [ ] `*-scm-1.rockspec` or `*-dev-1.rockspec` — development rockspec
- [ ] `*-X.Y.Z-1.rockspec` — release rockspec (versioned)
- [ ] `M.version` or `M._VERSION` in main module (`lua/<name>/init.lua`)
- [ ] `version` field in rockspec
- [ ] `pkg.json` or similar package manifest
- [ ] Release tags in git history (`v*` tags)

**Impact**: Determines Dimension 9 activation level:
| Signal | Activation |
|--------|-----------|
| No version field | Dimension skipped |
| Version in module only | Format validation only (quality gate) |
| Rockspec with version + release intent | Format validation + bump enforcement |

**Record**: Version source, version value, publish status.

---

## Analysis Output Format

After analysis, the setup skill should produce a structured summary:

```
Build system: Makefile + rockspec
Lua version: LuaJIT (Neovim)
Project structure: lua/myplugin/ + plugin/ + tests/ + doc/
Plugin type: utility (keymaps, commands)
Project size: ~2,000 LOC, 15 test files
Test framework: plenary.nvim
Existing tools: stylua (configured), selene (missing)
Missing dimensions: type safety, complexity, version discipline
CI: GitHub Actions (test job exists, no lint)
```

This summary drives the plan phase, where the skill selects which dimensions to configure and how.
