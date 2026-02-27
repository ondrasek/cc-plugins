# Analysis Checklist

This checklist defines what the setup skill must analyze in a target codebase before applying the methodology. Each section feeds into tool selection, configuration, and threshold decisions.

---

## 1. Package Manager

**Check for** (in priority order):
- [ ] `uv.lock` → uv
- [ ] `pyproject.toml` with `[tool.uv]` → uv
- [ ] `poetry.lock` → poetry
- [ ] `pdm.lock` → pdm
- [ ] `Pipfile.lock` → pipenv
- [ ] `requirements.txt` only → pip

**Impact**: Determines command prefix (`uv run`, `poetry run`, `pdm run`, or direct).

---

## 2. Python Version

**Check for**:
- [ ] `pyproject.toml` → `project.requires-python`
- [ ] `pyproject.toml` → `tool.ruff.target-version`
- [ ] `.python-version` file
- [ ] `Dockerfile` → `FROM python:X.Y`
- [ ] `setup.cfg` → `python_requires`

**Impact**: Sets `target-version` for ruff, `pythonVersion` for pyright, `python_version` for mypy, `--python-version` for refurb. Determines if ty is available (requires modern Python).

---

## 3. Project Structure

**Check for**:
- [ ] `src/` layout → source in `src/{package}/`
- [ ] Flat layout → source at top level alongside `pyproject.toml`
- [ ] `tests/` directory location
- [ ] Multiple packages (monorepo)

**Impact**: Determines paths for all tool invocations (`src/` vs `.`), pytest testpaths, coverage source.

---

## 4. Framework Detection

**Check for** (in `pyproject.toml` dependencies or imports):
- [ ] `django` → Django project
- [ ] `flask` → Flask project
- [ ] `fastapi` or `starlette` → FastAPI project
- [ ] `click` or `typer` → CLI application
- [ ] `celery` → Task queue
- [ ] `sqlalchemy` → ORM usage
- [ ] `pydantic` → Data validation (standalone or with FastAPI)
- [ ] No framework → Library or script

**Impact**:
- Django: add `django-stubs`, mypy plugin, semgrep `p/django` ruleset
- Flask: add semgrep `p/flask` ruleset
- FastAPI: pydantic mypy plugin
- Click/Typer: enable style-guide check
- Library: raise coverage threshold, raise docstring threshold

---

## 5. Existing Tool Configuration

**Check `pyproject.toml` for existing `[tool.*]` sections**:
- [ ] `[tool.ruff]` — existing ruff config
- [ ] `[tool.black]` — using black instead of ruff format
- [ ] `[tool.isort]` — using isort instead of ruff
- [ ] `[tool.flake8]` — using flake8 instead of ruff
- [ ] `[tool.mypy]` — existing mypy config
- [ ] `[tool.pytest]` or `[tool.pytest.ini_options]` — existing pytest config
- [ ] `[tool.coverage]` — existing coverage config
- [ ] `[tool.bandit]` — existing bandit config
- [ ] `[tool.pyright]` — existing pyright settings (or `pyrightconfig.json`)

**Also check for standalone config files**:
- [ ] `setup.cfg` — legacy tool configs
- [ ] `tox.ini` — tox-based test runner
- [ ] `.flake8` — standalone flake8 config
- [ ] `.mypy.ini` — standalone mypy config
- [ ] `.bandit` — standalone bandit config

**Impact**: Merge methodology config into existing config; don't overwrite user customizations. Migrate legacy tools (black → ruff format, flake8 → ruff, isort → ruff I rule).

---

## 6. Existing CI/CD

**Check for**:
- [ ] `.github/workflows/*.yml` — GitHub Actions
- [ ] `.gitlab-ci.yml` — GitLab CI
- [ ] `.circleci/config.yml` — CircleCI
- [ ] `Jenkinsfile` — Jenkins
- [ ] `.travis.yml` — Travis CI
- [ ] `azure-pipelines.yml` — Azure Pipelines

**Impact**: If CI exists, merge quality checks into existing pipeline rather than overwriting. If no CI, create `.github/workflows/ci.yml`.

---

## 7. Existing Claude Code Configuration

**Check for**:
- [ ] `.claude/settings.json` — existing hooks, permissions, statusline
- [ ] `.claude/hooks/` — existing hook scripts
- [ ] `CLAUDE.md` — existing project instructions

**Impact**: Merge hooks into existing settings.json. Don't overwrite existing CLAUDE.md — append methodology reference.

---

## 8. Project Maturity Signals

**Assess**:
- [ ] Git history length (commits, age)
- [ ] Lines of code (approximate via `find src/ -name '*.py' | xargs wc -l`)
- [ ] Number of test files
- [ ] Existing coverage percentage (if pytest-cov is configured)
- [ ] Number of contributors
- [ ] README quality

**Impact**: Determines initial thresholds:
| Signal | Coverage | Docstring | Complexity |
|--------|----------|-----------|------------|
| New (< 500 LOC) | 60% | 50% | C |
| Small (500–5k LOC) | 70% | 60% | B |
| Medium (5k–50k LOC) | 80% | 70% | B |
| Large (50k+ LOC) | 80% | 70% | B |
| Library | 90% | 90% | B |

---

## 9. Pre-commit

**Check for**:
- [ ] `.pre-commit-config.yaml` — existing pre-commit config
- [ ] Hooks already installed (`git config core.hooksPath` or `.git/hooks/pre-commit`)

**Impact**: If pre-commit exists, add ruff hooks if missing. If no pre-commit, create config and add to Makefile setup target.

---

## 10. Version & Packaging

**Check for**:
- [ ] `pyproject.toml` → `project.version` (PEP 621 static version)
- [ ] `pyproject.toml` → `tool.poetry.version` (Poetry)
- [ ] Source file `__version__` (legacy pattern)
- [ ] `pyproject.toml` → `dynamic = ["version"]` (dynamic versioning — setuptools-scm, hatch-vcs, etc.)
- [ ] `pyproject.toml` → `[build-system]` with `build-backend` (packaging intent)
- [ ] `pyproject.toml` → `[project.urls]` containing "pypi" (PyPI publishing intent)

**Impact**: Determines Dimension 9 activation level:
| Signal | Activation |
|--------|-----------|
| No version field | Dimension skipped |
| Static version, no build-system | Format validation only (quality gate) |
| Static version + build-system | Format validation + bump enforcement |
| Dynamic version (`dynamic = ["version"]`) | Format validation only (bump managed by tooling) |

**Record**: Version source, version value, packaging intent, dynamic versioning.

---

## Analysis Output Format

After analysis, the setup skill should produce a structured summary:

```
Package manager: uv
Python version: 3.13
Project structure: src layout (src/mypackage/)
Framework: FastAPI + Pydantic
Project size: ~2,500 LOC, 45 test files
Existing tools: ruff (configured), pytest (configured), mypy (basic)
Missing dimensions: security, complexity, dead code, documentation, architecture
CI: GitHub Actions (test + lint jobs exist)
```

This summary drives the plan phase, where the skill selects which dimensions to configure and how.
