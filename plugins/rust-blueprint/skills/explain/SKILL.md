---
name: explain
description: Answers questions about the Rust quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any methodology question.
metadata:
  version: 0.2.0
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

**"Why clippy instead of an external linter?"**
-> Read methodology.md Dimension 2 (Linting & Formatting). Explain that clippy is the standard Rust linter, deeply integrated with the compiler, and covers style, correctness, performance, and complexity lints. No external tool matches its coverage.

**"What's the coverage threshold and why?"**
-> Read methodology.md Dimension 1. Explain the 75% default and adaptation rules for different project types (60% new, 85% library).

**"Should I use all 9 dimensions?"**
-> Read methodology.md Principles (incremental adoption). Explain that projects can start with a subset and add dimensions over time. Reference the audit skill for tracking progress.

**"Why cargo-deny over cargo-vet?"**
-> Explain that cargo-deny covers advisories + licenses + duplicates + bans in one tool with a single config file. cargo-vet focuses on supply chain auditing which is complementary but more complex to set up.

**"How does the quality gate work?"**
-> Read methodology.md Hook Architecture section. Explain fail-fast ordering, exit code 2 feedback loop, and the automatic fix cycle.

**"Why is unsafe_code forbidden by default?"**
-> Read methodology.md Dimension 3. Explain that most application and library crates don't need unsafe code. The methodology forbids it by default and relaxes for FFI/interop crates.

**"How does WASM support work?"**
-> Read methodology.md WASM-Specific Considerations section. Explain detection, testing, CI, and quality gate adaptations for WASM targets.

**"How do I disable a check?"**
-> Explain that each check in the quality gate has a `[check:*]` comment marker. The setup skill removes disabled checks. For manual removal, delete the `run_check` block for that dimension.

## Important Notes

- Always cite which methodology document your answer comes from
- If a question is outside the methodology's scope, say so
- Suggest running `/rust-blueprint:audit` if the user wants to see their project's status
- Suggest running `/rust-blueprint:setup` if the user wants to apply changes
