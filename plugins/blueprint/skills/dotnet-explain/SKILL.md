---
name: dotnet-explain
description: Answers questions about the .NET quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any .NET methodology question.
metadata:
  version: 1.0.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# .NET Explain

Read-only — does not modify any files.

## Context Files

- `skills/shared/references/explain-pattern.md` — shared answer format and behavior
- `skills/shared/references/methodology-framework.md` — shared principles, hook architecture
- `skills/dotnet-setup/references/methodology.md` — .NET-specific dimensions, rationale, adaptation rules
- `skills/dotnet-setup/references/analysis-checklist.md` — how projects are analyzed

## Example Questions

**"Why Roslyn analyzers over external tools?"** → Dimension 2. Roslyn analyzers run during `dotnet build`, integrate with IDEs, controlled via .editorconfig. No separate step needed.

**"What's the coverage threshold?"** → Dimension 1. 90% default; 70% for new projects; legacy: start at current.

**"Should I use all 9 dimensions?"** → Principles: incremental adoption. Start with testing + linting, add incrementally.

**"Why Directory.Build.props?"** → .NET-Specific Patterns. Centralizes MSBuild properties, avoids duplication across .csproj files.

**"How does nullable reference types fit?"** → Dimension 3. `<Nullable>enable</Nullable>` + `AnalysisLevel: latest-Recommended`.

**"How do I disable a check?"** → Each check has a `[check:*]` comment marker. Delete the `run_check` block.
