# Tool Catalog

Reference for all tools used in the Python quality methodology. Each entry describes what the tool does, its default configuration, invocation, and alternatives.

The setup skill uses this catalog to select and configure tools based on the target project's ecosystem.

---

## Package Management

### uv (default)

**Purpose**: Fast Python package manager and project runner.

**Why default**: Fastest resolver, built-in virtual env management, lockfile support, `uv run` eliminates activation.

**Config**: None required (uses `pyproject.toml`).

**Detection**: `uv.lock` exists, or `pyproject.toml` has `[tool.uv]`.

**Alternatives**:
- **pip + venv**: Universal fallback. Replace `uv run X` with `python -m X` or activate venv first.
- **poetry**: Replace `uv sync` with `poetry install`, `uv run` with `poetry run`.
- **pdm**: Replace `uv sync` with `pdm install`, `uv run` with `pdm run`.

**Adaptation**: All hook scripts and CI use `uv run`. When a different package manager is detected, the setup skill rewrites commands accordingly.

---

## Testing

### pytest

**Purpose**: Test runner. Discovers and executes test files matching `test_*.py`.

**Default config** (pyproject.toml):
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
norecursedirs = [".venv", "dist", "build"]
```

**Quality gate invocation**: `uv run pytest -x --tb=short`

**Key flags**:
- `-x` — stop on first failure (fail-fast)
- `--tb=short` — concise tracebacks
- `--cov=src/` — enable coverage
- `--cov-fail-under=80` — enforce minimum coverage

**Dev dependencies**: `pytest`, `pytest-cov`

### pytest-cov

**Purpose**: Coverage measurement plugin for pytest.

**Quality gate invocation**: `uv run pytest --cov=src/ --cov-report=term --cov-fail-under=80 -q`

**CI invocation**: `uv run pytest --cov --cov-report=term-missing --cov-report=xml` (XML for Codecov upload)

---

## Linting & Formatting

### ruff

**Purpose**: Extremely fast Python linter and formatter. Replaces flake8, isort, pyupgrade, and black.

**Default config** (pyproject.toml):
```toml
[tool.ruff]
target-version = "py313"
line-length = 100

[tool.ruff.lint]
select = ["E", "W", "F", "I", "UP", "B", "SIM"]

[tool.ruff.format]
quote-style = "double"
```

**Rule sets**:
| Code | Source | What it catches |
|------|--------|----------------|
| E | pycodestyle | Style errors |
| W | pycodestyle | Style warnings |
| F | pyflakes | Undefined names, unused imports |
| I | isort | Import ordering |
| UP | pyupgrade | Deprecated Python patterns |
| B | bugbear | Common bugs and design problems |
| SIM | simplify | Unnecessarily complex expressions |

**Quality gate**: `uv run ruff check src/ tests/` + `uv run ruff format --check src/ tests/`

**Per-edit hook**: `uv run ruff check --fix --quiet $FILE` + `uv run ruff format --quiet $FILE`

**Dev dependency**: `ruff`

### codespell

**Purpose**: Spell checker for source code. Catches typos in identifiers, strings, and comments.

**Default config** (pyproject.toml):
```toml
[tool.codespell]
skip = ".venv,*.pyc,__pycache__,.git"
```

**Per-edit hook**: `uv run codespell --write-changes --quiet-level=2 $FILE`

**Dev dependency**: `codespell>=2.3`

---

## Type Checking

### pyright

**Purpose**: Fast static type checker from Microsoft. Excellent inference, good IDE integration.

**Default config** (pyrightconfig.json):
```json
{
  "include": ["src"],
  "exclude": ["**/__pycache__", ".venv"],
  "pythonVersion": "3.13",
  "typeCheckingMode": "standard",
  "reportMissingImports": true,
  "reportMissingTypeStubs": false
}
```

**Quality gate**: `uv run pyright src/`

**Dev dependency**: `pyright>=1.1`

### mypy

**Purpose**: Gradual type checker. Strict mode catches more issues than pyright in some areas (e.g., return type inference).

**Default config** (pyproject.toml):
```toml
[tool.mypy]
python_version = "3.13"
strict = true
warn_return_any = true
warn_unused_ignores = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
```

**Quality gate**: `uv run mypy src/`

**Dev dependency**: `mypy>=1.15`

### ty

**Purpose**: Additional type checker (from the Astral/ruff ecosystem). Catches some issues others miss.

**Default config** (pyproject.toml):
```toml
[tool.ty.environment]
python-version = "3.13"

[tool.ty.src]
exclude = ["tests/**", "**/__pycache__"]
```

**Quality gate**: `uv run ty check src/`

**Dev dependency**: `ty>=0.0.1a1`

---

## Security

### bandit

**Purpose**: Finds common security issues in Python code (hardcoded passwords, shell injection, insecure crypto).

**Default config** (pyproject.toml):
```toml
[tool.bandit]
exclude_dirs = ["tests", ".venv"]
skips = ["B101"]
```

**B101 skip rationale**: `assert` is used for internal invariants, not input validation.

**Quality gate**: `uv run bandit -r src/ -q -ll`

**Dev dependency**: `bandit>=1.8`

### semgrep

**Purpose**: Lightweight static analysis with pattern-matching rules. Broader than bandit — catches correctness and style issues too.

**Quality gate**: `uv run semgrep scan --config p/python --error --quiet src/`

**Available rulesets**: `p/python`, `p/django`, `p/flask`, `p/owasp-top-ten`, `p/secrets`

**Note**: Semgrep is the slowest tool in the quality gate. Consider CI-only for large codebases.

**Dev dependency**: `semgrep>=1.50`

---

## Complexity

### xenon

**Purpose**: Enforces cyclomatic complexity limits per function, module, and project-wide.

**Default config** (pyproject.toml):
```toml
[tool.xenon]
max-absolute = "B"
max-modules = "A"
max-average = "A"
```

**Grade scale**: A (CC 1–5) → B (CC 6–10) → C (CC 11–15) → D (CC 16–25) → E (CC 26–50) → F (CC 50+)

**Quality gate**: `uv run xenon --max-absolute B --max-modules A --max-average A src/`

**Dev dependency**: `xenon>=0.9`

---

## Dead Code & Modernization

### vulture

**Purpose**: Finds unused code (functions, variables, imports, classes).

**Default invocation**: `uv run vulture src/ --min-confidence 80`

**Note**: Uses "nonempty output = fail" pattern — vulture exits 0 even with findings.

**Whitelisting**: For public API or dynamic usage, create a whitelist file.

**Dev dependency**: `vulture>=2.14`

### refurb

**Purpose**: Suggests modern Python idioms. Replaces old patterns with cleaner alternatives.

**Default invocation**: `uv run refurb src/ --python-version 3.13`

**Note**: Uses "nonempty output = fail" pattern like vulture.

**Dev dependency**: `refurb>=2.0`

---

## Documentation

### interrogate

**Purpose**: Measures docstring coverage. Reports which public functions/classes/modules lack docstrings.

**Default config** (pyproject.toml):
```toml
[tool.interrogate]
exclude = ["tests", "docs"]
ignore-init-method = true
ignore-init-module = true
ignore-magic = true
ignore-semiprivate = true
ignore-private = true
fail-under = 70
verbose = 0
```

**Quality gate**: `uv run interrogate src/ -v --fail-under 70 -e tests/`

**Dev dependency**: `interrogate>=1.7`

---

## Architecture

### import-linter

**Purpose**: Enforces import boundaries between modules. Prevents circular dependencies and layer violations.

**Default config** (pyproject.toml):
```toml
[tool.importlinter]
root_packages = ["your_package"]
```

**Contract types**:
- `forbidden` — module A must not import module B
- `layers` — enforce top-down dependency (views → services → models)
- `independence` — modules must not import each other

**Quality gate**: `uv run lint-imports`

**Dev dependency**: `import-linter>=2.0`

### deptry

**Purpose**: Dependency hygiene — finds unused, missing, and transitive dependencies in `pyproject.toml`.

**Default config** (pyproject.toml):
```toml
[tool.deptry]
ignore = ["DEP003"]
```

**Session start hook**: `uv run deptry .` (non-blocking)

**Dev dependency**: `deptry>=0.20`

---

## Pre-commit

### ruff-pre-commit

**Purpose**: Runs ruff lint and format checks on `git commit`.

**Default config** (.pre-commit-config.yaml):
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.4
    hooks:
      - id: ruff
      - id: ruff-format
```

**Setup**: `uv run pre-commit install` (via Makefile `setup` target)

**Dev dependency**: `pre-commit`

---

## Full Dev Dependency List

```toml
[dependency-groups]
dev = [
    "pre-commit",
    "pytest",
    "pytest-cov",
    "ruff",
    "pyright>=1.1",
    "bandit>=1.8",
    "vulture>=2.14",
    "xenon>=0.9",
    "refurb>=2.0",
    "deptry>=0.20",
    "import-linter>=2.0",
    "codespell>=2.3",
    "semgrep>=1.50",
    "ty>=0.0.1a1",
    "interrogate>=1.7",
    "mypy>=1.15",
]
```
