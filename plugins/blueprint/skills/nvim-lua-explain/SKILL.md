---
name: nvim-lua-explain
description: Answers questions about the Neovim Lua quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why selene", "what does the quality gate do", "how are thresholds set", or any Neovim Lua methodology question.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Neovim Lua Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/explain-pattern.md` — shared answer format and behavior
- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture
- `skills/nvim-lua-setup/references/methodology.md` — Neovim Lua-specific dimensions, rationale, adaptation rules
- `skills/nvim-lua-setup/references/analysis-checklist.md` — how projects are analyzed

## Example Questions

**"Why selene instead of luacheck?"** → Dimension 2. Selene is actively maintained, supports custom std libraries for Neovim globals, better error messages, community standard.

**"What's the coverage threshold?"** → Dimension 1. 75% default; 50% new; 80% library. Lua coverage tooling (luacov) is less mature.

**"Why StyLua for formatting?"** → Dimension 2. Fast (written in Rust), opinionated, supports LuaJIT syntax, widely adopted in Neovim ecosystem.

**"Why is security analysis limited?"** → Dimension 4. No Lua equivalent of bandit/cargo-audit. Uses selene rules + grep patterns.

**"How does testing work with Neovim?"** → Dimension 1. Test framework detection (plenary, mini.test, busted), headless Neovim execution, minimal_init.lua.

**"Why LuaJIT and not Lua 5.4?"** → Neovim Lua-Specific Patterns. Neovim embeds LuaJIT (Lua 5.1). All tools must target LuaJIT.
