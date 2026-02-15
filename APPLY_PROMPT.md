# Blueprint Apply Instructions

You are applying the `python-blueprint` to this project. The blueprint lives at `.blueprint/` (a git submodule). Follow these instructions precisely.

## 1. Direct Copy (overwrite)

Copy these directories/files from `.blueprint/` to the project root, overwriting any existing files:

- `.claude/` — entire directory (settings, hooks, agents, commands, statusline)
- `.devcontainer/` — entire directory
- `.github/workflows/ci.yml`
- `Makefile`
- `pyrightconfig.json`
- `.pre-commit-config.yaml`

Use the Read tool to read each source file from `.blueprint/`, then use Write to write it to the project root at the same relative path.

## 2. Smart Merge: pyproject-tools.toml into pyproject.toml

Read `.blueprint/pyproject-tools.toml`. This contains `[tool.*]` sections and `[dependency-groups] dev`.

If the project has an existing `pyproject.toml`:
- **Add** any `[tool.*]` sections that don't already exist
- **Update** `[tool.*]` sections that exist in both (blueprint wins)
- **Merge** `[dependency-groups] dev` — add any packages from the blueprint that aren't already listed
- **Preserve** the project's `[build-system]`, `[project]`, `[project.scripts]`, and any other non-tool sections untouched
- **Update** `[tool.importlinter] root_packages` to match the project's actual package name (look at `[project] name` or the `src/` directory)

If there is no `pyproject.toml`, create one with a minimal `[build-system]` and `[project]` section, then add all the tool sections.

## 3. Smart Merge: gitignore.blueprint into .gitignore

Read `.blueprint/gitignore.blueprint`.

If the project has an existing `.gitignore`:
- Add any entries from the blueprint that aren't already present
- Don't duplicate entries that already exist
- Append new entries at the end, separated by a comment `# Added by python-blueprint`

If there is no `.gitignore`, copy `gitignore.blueprint` as `.gitignore`.

## 4. Skip If Exists: CLAUDE.md

Only if `CLAUDE.md` does NOT exist in the project root:
- Copy `.blueprint/CLAUDE.md.blueprint` as `CLAUDE.md`

If `CLAUDE.md` already exists, do not modify it.

## 5. Do NOT Touch

Never modify any of these:
- `src/` — project source code
- `tests/` — project tests
- `README.md` — project documentation
- Any other project-specific files not mentioned above

## 6. Post-Apply Verification

After applying, verify:
1. All `.sh` files under `.claude/hooks/` and `.devcontainer/` have executable permissions (use `chmod +x` via Bash if needed)
2. Read the resulting `pyproject.toml` to confirm the merge looks correct
3. Report what was done: files copied, files merged, files skipped
