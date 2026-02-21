---
name: explain
description: Answers questions about the Python quality methodology — why tools are chosen, how thresholds work, what each dimension covers, and how hooks interact. Use when user asks "why this tool", "what does the quality gate do", "how are thresholds set", or any methodology question.
metadata:
  version: 0.2.1
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

**"Why do you use ruff instead of black + flake8 + isort?"**
→ Read methodology.md Dimension 2 (Linting & Formatting). Explain that the methodology defines roles — the setup skill researches and selects the best current tools to fill each role. If it chose ruff, explain why based on the research criteria in methodology.md (speed, pyproject.toml support, community adoption).

**"What's the coverage threshold and why?"**
→ Read methodology.md Dimension 1. Explain the 80% default and adaptation rules for different project types.

**"Should I use all 8 dimensions?"**
→ Read methodology.md Principles (incremental adoption). Explain that projects can start with a subset and add dimensions over time. Reference the audit skill for tracking progress.

**"Why is B the default complexity grade?"**
→ Read methodology.md Dimension 5. Explain the CC 10 threshold and why it balances maintainability with practicality.

**"How does the quality gate work?"**
→ Read methodology.md Hook Architecture section. Explain fail-fast ordering, exit code 2 feedback loop, and the automatic fix cycle.

**"What adaptations are there for Django projects?"**
→ Read methodology.md adaptation rules across all dimensions. Compile Django-specific guidance: type stubs, framework-specific security rules, layer contracts.

**"How do I disable a check?"**
→ Explain that each check in the quality gate has a comment marker. The setup skill removes disabled checks. For manual removal, delete the `run_check` block for that dimension.

**"When do import contracts get activated?"**
→ Read methodology.md Dimension 8 (progressive activation). Explain the three stages: circular import detection only, then contract bootstrapping on first violation, then enforcement.

## Important Notes

- Always cite which methodology document your answer comes from
- If a question is outside the methodology's scope, say so
- Suggest running `/python-blueprint:audit` if the user wants to see their project's status
- Suggest running `/python-blueprint:setup` if the user wants to apply changes
