# /python-blueprint:explain

Answer questions about the Python quality methodology — why specific tools are included, how thresholds were chosen, and what each dimension covers.

**This skill is read-only — it does not modify any files.**

## Context Files

Read these files from the plugin to answer questions:

- `skills/setup/methodology.md` — quality dimensions, rationale, adaptation rules
- `skills/setup/tool-catalog.md` — tool descriptions, alternatives, configuration details
- `skills/setup/analysis-checklist.md` — how projects are analyzed

## Behavior

This skill responds to free-form questions about the methodology. It does not follow a fixed workflow.

### Example Questions and How to Answer

**"Why do you use ruff instead of black + flake8 + isort?"**
→ Read tool-catalog.md's ruff entry. Explain that ruff replaces all three tools with better performance and a single config point.

**"What's the coverage threshold and why?"**
→ Read methodology.md Dimension 1. Explain the 80% default and adaptation rules for different project types.

**"Should I use all 15 checks?"**
→ Read methodology.md principles. Explain incremental adoption — projects can start with a subset and add dimensions over time. Reference the audit skill for tracking progress.

**"Why is B the default complexity grade?"**
→ Read methodology.md Dimension 5 and tool-catalog.md xenon entry. Explain the McCabe/NIST grading scale and why CC ≤ 10 is a practical threshold.

**"What's the difference between pyright and mypy?"**
→ Read tool-catalog.md entries for both. Explain their complementary strengths — pyright has better inference, mypy has stricter enforcement in some areas.

**"How does the quality gate work?"**
→ Read methodology.md Hook Architecture section. Explain fail-fast ordering, exit code 2 feedback loop, and the automatic fix cycle.

**"What adaptations are there for Django projects?"**
→ Read methodology.md adaptation rules across all dimensions. Compile Django-specific guidance: django-stubs, mypy plugin, semgrep rulesets, layer contracts.

**"How do I disable a check?"**
→ Explain that each check in the quality gate template has a `[check:name]` comment marker. The setup skill removes disabled checks. For manual removal, delete the `run_check` line between the markers.

## Important Notes

- Always cite which methodology document your answer comes from
- If a question is outside the methodology's scope, say so
- Suggest running `/python-blueprint:audit` if the user wants to see their project's status
- Suggest running `/python-blueprint:setup` if the user wants to apply changes
