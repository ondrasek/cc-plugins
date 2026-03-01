# Explain Pattern

Read-only — does not modify any files.

The explain skill answers free-form questions about the vault quality methodology. It does not follow a fixed workflow. The vault-specific explain SKILL.md provides example questions and which methodology sections to reference.

---

## Behavior

1. Read the vault-specific `methodology.md` and `analysis-checklist.md` to answer questions
2. Cite which document and section the answer comes from
3. If a question is outside the methodology's scope, say so
4. Suggest running the audit skill if the user wants to see their vault's status
5. Suggest running the setup skill if the user wants to apply changes

---

## Common Question Categories

- **Dimension scope** — "What does Frontmatter Integrity cover?" / "What counts as a naming convention violation?"
- **Tool choices** — "Why this tool instead of that one?" / "Can I use the Obsidian Linter plugin instead?"
- **Thresholds** — "What's the spelling error threshold and why?" / "How strict is template compliance?"
- **Hook mechanics** — "How does the quality gate work?" / "What triggers per-edit checks?"
- **Workflow questions** — "What GitHub Actions workflows are available?" / "How does calendar sync work?"
- **Vault conventions** — "Should daily notes have frontmatter?" / "How should I name folders?"

---

## Answer Format

- Be specific — reference exact sections from the methodology
- Explain the rationale, not just the rule
- Mention adaptation rules when relevant (personal vault vs team vault)
- Keep answers concise but complete
- When comparing tools, include ecosystem context (npm packages, Obsidian plugins, CLI tools)
