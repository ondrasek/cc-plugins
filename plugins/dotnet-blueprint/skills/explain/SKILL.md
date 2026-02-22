---
name: explain
description: Answers questions about the .NET quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this analyzer", "what does the quality gate do", "how are thresholds set", or any methodology question.
metadata:
  version: 0.1.0
  author: ondrasek
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

**"Why do you use StyleCop instead of just .editorconfig?"**
→ Read methodology.md Dimension 2 (Linting & Formatting). Explain that .editorconfig handles formatting, but Roslyn analyzers like StyleCop enforce deeper code style patterns (naming, documentation, ordering) that .editorconfig cannot express. The methodology defines roles — the setup skill researches and selects the best current analyzers.

**"What's the coverage threshold and why?"**
→ Read methodology.md Dimension 1. Explain the 90% default and adaptation rules for different project types.

**"Should I use all 9 dimensions?"**
→ Read methodology.md Principles (incremental adoption). Explain that projects can start with a subset and add dimensions over time. Reference the audit skill for tracking progress.

**"Why enforce nullable reference types?"**
→ Read methodology.md Dimension 3. Explain that nullable reference types are C#'s built-in null safety feature. Enabling them catches null reference exceptions at compile time rather than runtime.

**"How does the quality gate work?"**
→ Read methodology.md Hook Architecture section. Explain fail-fast ordering, exit code 2 feedback loop, and the automatic fix cycle.

**"What adaptations are there for ASP.NET Core projects?"**
→ Read methodology.md adaptation rules across all dimensions. Compile ASP.NET Core-specific guidance: security analyzers, controller naming, DI patterns, layer architecture.

**"How do I disable a check?"**
→ Explain that each check in the quality gate has a comment marker. The setup skill removes disabled checks. For manual removal, delete the `run_check` block for that dimension. For analyzer rules, set severity to `none` in .editorconfig.

**"When do architecture tests get activated?"**
→ Read methodology.md Dimension 8 (progressive activation). Explain the three stages: basic dependency validation only, then architecture test bootstrapping on first violation, then enforcement.

**"Why use Directory.Build.props instead of per-project config?"**
→ Read methodology.md .NET-Specific Patterns section. Explain centralization avoids duplication, ensures all projects in the solution share the same quality bar, and makes updates a single-file change.

## Important Notes

- Always cite which methodology document your answer comes from
- If a question is outside the methodology's scope, say so
- Suggest running `/dotnet-blueprint:audit` if the user wants to see their project's status
- Suggest running `/dotnet-blueprint:setup` if the user wants to apply changes
