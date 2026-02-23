#!/usr/bin/env bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# Repo-agnostic: scans all Python code in the repository. Each tool uses its
# own config (pyproject.toml, pyrightconfig.json, etc.) for includes/excludes.

set -o pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

HOOK_LOG="${CLAUDE_PROJECT_DIR}/.claude/hooks/hook-debug.log"
mkdir -p "$(dirname "$HOOK_LOG")" 2>/dev/null
debuglog() {
    echo "[quality-gate] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

# Skip entirely if no Python files exist
if ! find . -name '*.py' -not -path './.venv/*' -not -path './.git/*' -print -quit 2>/dev/null | grep -q .; then
    debuglog "No Python files found, skipping quality gate"
    exit 0
fi

# Per-tool diagnostic hints. Keyed by the NAME passed to run_check/run_check_nonempty.
# These tell Claude how to investigate and fix each type of failure.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [pytest]="Read the failing test file and the source it tests. Run 'uv run pytest path/to/test_file.py::TestClass::test_name -x --tb=long' to see the full traceback. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run 'uv run pytest --cov --cov-report=term-missing' to see which lines are uncovered. Add tests for the uncovered code paths. Configure [tool.coverage.run] in pyproject.toml to set source directories."
    [ruff check]="Run 'uv run ruff check --output-format=full' for detailed explanations. Most issues are auto-fixable with 'uv run ruff check --fix'. Read the file at the reported line before editing."
    [ruff format]="Run 'uv run ruff format' to auto-fix all formatting issues."
    [pyright]="Read the file at the reported line number. Check type annotations, imports, and function signatures. Run 'uv run pyright path/to/file.py' to re-check a single file after fixing."
    [mypy]="Read the file at the reported line number. Fix type annotations — add missing type params, annotate untyped defs, fix incompatible assignments. Run 'uv run mypy path/to/file.py' to re-check a single file after fixing."
    [bandit]="Read the flagged code. Common fixes: use 'secrets' module instead of random for security, avoid shell=True in subprocess calls, use parameterized queries for SQL. Run 'uv run bandit -r . -ll --format custom --msg-template \"{relpath}:{line} {test_id} {msg}\"' for concise output."
    [vulture]="The reported code is detected as unused (dead code). Read the file to verify it is truly unused. If it is, delete it. If it's used dynamically (e.g. via getattr or as a public API), add it to a vulture whitelist."
    [xenon]="The reported function has cyclomatic complexity rank C or worse (CC > 10). Read the function and extract helper functions to reduce branching. Each 'if', 'elif', 'for', 'while', 'and', 'or', 'except', ternary, and comprehension-if adds +1 CC. Target: every function at rank B or better (CC <= 10)."
    [refurb]="Run 'uv run refurb --explain ERRCODE' (e.g. 'uv run refurb --explain FURB123') to understand the suggested modernization. These are usually simple one-line replacements. Read the file at the reported line, apply the suggested fix."
    [import-linter]="Check the import layering rules in pyproject.toml under [tool.importlinter]. The error shows which import violates the dependency contract. Fix by restructuring the import or moving code to the correct layer."
    [ty]="Read the file at the reported line. Fix type errors — check annotations, return types, and argument types. Run 'uv run ty check path/to/file.py' to re-check a single file."
    [interrogate]="The reported module or function is missing a docstring. Add a one-line docstring to each flagged public function/class/module. Run 'uv run interrogate . -v --fail-under 70' to see which are missing."
    [style-guide]="CLI output formatting must follow the style guide: section headings use emoji + click.style(ALL CAPS text, fg=COLOR, bold=True). No ASCII splitter lines (===, ---, ***). Fix by replacing raw print/echo of splitter lines with styled headings."
)

fail() {
    local name="$1"
    local cmd="$2"
    local output="$3"
    local hint="${TOOL_HINTS[$name]:-}"

    echo "" >&2
    echo "QUALITY GATE FAILED [$name]:" >&2
    echo "Command: $cmd" >&2
    echo "" >&2
    echo "$output" >&2
    echo "" >&2
    if [ -n "$hint" ]; then
        echo "Hint: $hint" >&2
        echo "" >&2
    fi
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or explain — read the failing file, edit the source code to resolve it, and the quality gate will re-run automatically." >&2
    debuglog "=== FAILED: $name ==="
    exit 2
}

# run_check NAME COMMAND...
# Runs the command, fails fast if exit code is non-zero.
run_check() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1) || fail "$name" "$cmd" "$OUTPUT"
}

# run_check_nonempty NAME COMMAND...
# Runs the command, fails fast if exit code is non-zero AND there is output.
# Used for tools like vulture/refurb where exit 0 with no output = clean.
run_check_nonempty() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1)
    [ -n "$OUTPUT" ] && fail "$name" "$cmd" "$OUTPUT"
}

# ─── Style guide check (inline) ──────────────────────────────────────────────
# Only runs if the project uses click/typer for CLI output.
# Rules:
#   1. No ASCII art splitter lines (===, ---, ***) in click.echo/print calls
#   2. Section headings must use click.style() with bold=True and a color

check_style_guide() {
    # Find Python files that import click
    local CLI_FILES=()
    while IFS= read -r -d '' f; do
        if grep -qE '(import click|from click)' "$f" 2>/dev/null; then
            CLI_FILES+=("$f")
        fi
    done < <(find . -name '*.py' -not -path './.venv/*' -not -path './.git/*' -print0 2>/dev/null)

    # No click files — skip silently
    [ ${#CLI_FILES[@]} -eq 0 ] && return 0

    local ERRORS=()
    for f in "${CLI_FILES[@]}"; do
        [ -f "$f" ] || continue
        local relpath="${f#./}"

        # Rule 1: No ASCII splitter lines in echo/print calls
        while IFS= read -r match; do
            ERRORS+=("$relpath: ASCII splitter line — use emoji + click.style(ALL CAPS, bold=True) instead: $match")
        done < <(grep -nE '(echo|print)\(.*"[=\-\*]{3,}' "$f" 2>/dev/null || true)

        # Rule 2: Section heading echo() calls should use click.style with bold
        while IFS= read -r match; do
            if echo "$match" | grep -q 'click\.style'; then
                continue
            fi
            ERRORS+=("$relpath: Unstyled ALL-CAPS heading — wrap with click.style(..., bold=True, fg=COLOR): $match")
        done < <(grep -nE 'click\.echo\("[^"]*[A-Z]{3,}[^"]*"\)' "$f" 2>/dev/null || true)
    done

    if [ ${#ERRORS[@]} -gt 0 ]; then
        local output="STYLE GUIDE VIOLATIONS:\n\n"
        for err in "${ERRORS[@]}"; do
            output+="  - $err\n"
        done
        output+="\nDesign rules: Section headings must use emoji + click.style(ALL CAPS text, fg=COLOR, bold=True). No ASCII splitter lines (===, ---, ***)."
        printf '%b' "$output"
        return 1
    fi

    return 0
}

# ─── Checks ordered by speed and likelihood of failure ────────────────────────

# Skip pytest/coverage if no test files exist
TEST_FILES=$(find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -v ".venv" | head -1)
if [ -n "$TEST_FILES" ]; then
    run_check          "pytest"         uv run pytest -x --tb=short -m "not slow"
    run_check          "coverage"       uv run pytest --cov --cov-report=term --cov-fail-under=80 -q -m "not slow"
else
    debuglog "Skipping pytest/coverage (no test files found)"
fi
run_check          "ruff check"     uv run ruff check .
run_check          "ruff format"    uv run ruff format --check .
run_check          "pyright"        uv run pyright .
run_check          "mypy"           uv run mypy .
run_check          "bandit"         uv run bandit -r . -q -ll
run_check_nonempty "vulture"        uv run vulture . --min-confidence 80
run_check          "xenon"          uv run xenon --max-absolute B --max-modules A --max-average A .
run_check_nonempty "refurb"         uv run refurb .
run_check          "import-linter"  uv run lint-imports
run_check          "ty"             uv run ty check .
run_check          "interrogate"    uv run interrogate . -v --fail-under 70
# Style guide runs as a function — call directly, capture output
debuglog "Running style-guide..."
STYLE_OUTPUT=$(check_style_guide 2>&1)
if [ -n "$STYLE_OUTPUT" ]; then
    fail "style-guide" "check_style_guide (inline)" "$STYLE_OUTPUT"
fi

debuglog "=== ALL 14 CHECKS PASSED ==="
exit 0
