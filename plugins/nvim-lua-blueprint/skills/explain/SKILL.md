---
name: explain
description: Answers questions about the Neovim Lua quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why selene", "what does the quality gate do", "how are thresholds set", or any methodology question.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Explain

Read-only — does not modify any files.

## Context Files

Read these files from the plugin to answer questions:

- `skills/setup/methodology.md` — quality dimensions (roles), rationale, adaptation rules
- `skills/setup/analysis-checklist.md` — how projects are analyzed

## Behavior

This skill responds to free-form questions about the methodology. It does not follow a fixed workflow.

### Example Questions and How to Answer

**"Why selene instead of luacheck?"**
-> Read methodology.md Dimension 2 (Linting & Formatting). Explain that selene is actively maintained, supports custom std libraries for Neovim globals, has better error messages, and is the community standard for Neovim plugin development. Luacheck is no longer actively maintained.

**"What's the coverage threshold and why?"**
-> Read methodology.md Dimension 1. Explain the 75% default and adaptation rules for different project types (50% new, 80% library). Note that Lua coverage tooling (luacov) is less mature than other ecosystems, so thresholds are lower.

**"Should I use all 9 dimensions?"**
-> Read methodology.md Principles (incremental adoption). Explain that projects can start with a subset and add dimensions over time. Recommend starting with linting + formatting (Dimension 2) and testing (Dimension 1), then adding others incrementally.

**"Why StyLua for formatting?"**
-> Explain that StyLua is the standard Lua formatter in the Neovim ecosystem. It's fast (written in Rust), opinionated, supports LuaJIT syntax, and is widely adopted. The alternative (lua-format) is slower and less actively maintained.

**"How does the quality gate work?"**
-> Read methodology.md Hook Architecture section. Explain fail-fast ordering, exit code 2 feedback loop, and the automatic fix cycle.

**"Why is security analysis limited?"**
-> Read methodology.md Dimension 4. Explain that Lua doesn't have an equivalent of bandit (Python) or cargo-audit (Rust). The security dimension uses selene rules and grep-based pattern matching for dangerous calls like os.execute and loadstring.

**"How does testing work with Neovim?"**
-> Read methodology.md Dimension 1. Explain test framework detection (plenary, mini.test, busted), headless Neovim execution, and the minimal_init.lua pattern.

**"How do I disable a check?"**
-> Explain that each check in the quality gate has a `[check:*]` comment marker. The setup skill removes disabled checks. For manual removal, delete the `run_check` block for that dimension.

**"Why LuaJIT and not Lua 5.4?"**
-> Explain that Neovim embeds LuaJIT, which implements Lua 5.1 with select 5.2 features. All tools must be configured for LuaJIT/Lua 5.1 compatibility.

## Important Notes

- Always cite which methodology document your answer comes from
- If a question is outside the methodology's scope, say so
- Suggest running `/nvim-lua-blueprint:audit` if the user wants to see their project's status
- Suggest running `/nvim-lua-blueprint:setup` if the user wants to apply changes
