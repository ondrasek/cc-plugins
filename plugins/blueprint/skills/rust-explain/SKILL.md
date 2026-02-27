---
name: rust-explain
description: Answers questions about the Rust quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any Rust methodology question.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Rust Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/explain-pattern.md` — shared answer format and behavior
- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture
- `skills/rust-setup/references/methodology.md` — Rust-specific dimensions, rationale, adaptation rules
- `skills/rust-setup/references/analysis-checklist.md` — how projects are analyzed

## Example Questions

**"Why clippy instead of an external linter?"** → Dimension 2. Clippy is deeply integrated with the compiler, covering style, correctness, performance, complexity. No external tool matches its coverage.

**"What's the coverage threshold?"** → Dimension 1. 75% default; 60% new; 85% library.

**"Why cargo-deny over cargo-vet?"** → Dimension 4. cargo-deny covers advisories + licenses + duplicates + bans in one config file.

**"Why is unsafe_code forbidden by default?"** → Dimension 3. Most crates don't need unsafe. FFI/interop crates relax this.

**"How does WASM support work?"** → WASM-Specific Considerations section. Detection, testing, CI, and quality gate adaptations.

**"How do I disable a check?"** → Each check has a `[check:*]` comment marker. Delete the `run_check` block.
