#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below (ruff, pyright, mypy,
# bandit, vulture, xenon, etc.) are current best-in-class choices as of 2025.
# The setup skill should research and substitute the best tools for each ROLE
# based on the project's ecosystem. What matters is the PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${PACKAGE_MANAGER_RUN}  — command prefix (e.g., "uv run --no-sync", "poetry run")
#   ${SOURCE_DIR}           — source directory (e.g., "src/", "mypackage/")
#   ${TEST_DIR}             — test directory (e.g., "tests/")
#   ${PYTHON_VERSION}       — target Python version (e.g., "3.13")
#   ${COVERAGE_THRESHOLD}   — minimum coverage percentage (e.g., 80)
#   ${DOCSTRING_THRESHOLD}  — minimum docstring coverage (e.g., 70)
#   ${COMPLEXITY_GRADE}     — max absolute complexity grade (e.g., "B")
#   ${VULTURE_CONFIDENCE}   — min confidence for dead code (e.g., 80)
#
# ENABLED CHECKS (setup skill removes disabled ones and adds researched tools):
#   Each check is guarded by a comment marker for easy removal.

set -o pipefail

HOOK_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log"
debuglog() {
    echo "[quality-gate] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

# Per-tool diagnostic hints for Claude auto-fix.
# EXAMPLE HINTS: These are for the tools shown below. When substituting
# different tools, write hints that are SPECIFIC to that tool — tell Claude
# which file to read, how to re-check a single file, and what to fix.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [pytest]="Read the failing test file and the source it tests. Run '${PACKAGE_MANAGER_RUN} pytest path/to/test_file.py::TestClass::test_name -x --tb=long' to see the full traceback. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run '${PACKAGE_MANAGER_RUN} pytest --cov=${SOURCE_DIR} --cov-report=term-missing' to see which lines are uncovered. Add tests for the uncovered code paths."
    [ruff check]="Run '${PACKAGE_MANAGER_RUN} ruff check ${SOURCE_DIR} ${TEST_DIR} --output-format=full' for detailed explanations. Most issues are auto-fixable with '${PACKAGE_MANAGER_RUN} ruff check --fix'. Read the file at the reported line before editing."
    [ruff format]="Run '${PACKAGE_MANAGER_RUN} ruff format ${SOURCE_DIR} ${TEST_DIR}' to auto-fix all formatting issues."
    [pyright]="Read the file at the reported line number. Check type annotations, imports, and function signatures. Run '${PACKAGE_MANAGER_RUN} pyright ${SOURCE_DIR}path/to/file.py' to re-check a single file after fixing."
    [mypy]="Read the file at the reported line number. Fix type annotations — add missing type params, annotate untyped defs, fix incompatible assignments. Run '${PACKAGE_MANAGER_RUN} mypy ${SOURCE_DIR}path/to/file.py' to re-check a single file after fixing."
    [bandit]="Read the flagged code. Common fixes: use 'secrets' module instead of random for security, avoid shell=True in subprocess calls, use parameterized queries for SQL."
    [vulture]="The reported code is detected as unused (dead code). Read the file to verify it is truly unused. If it is, delete it. If it's used dynamically (e.g. via getattr or as a public API), add it to a vulture whitelist."
    [xenon]="The reported function has cyclomatic complexity rank C or worse (CC > 10). Read the function and extract helper functions to reduce branching."
    [refurb]="Run '${PACKAGE_MANAGER_RUN} refurb --explain ERRCODE' to understand the suggested modernization. These are usually simple one-line replacements."
    [import-linter]="Check the import layering rules in pyproject.toml under [tool.importlinter]. The error shows which import violates the dependency contract."
    [semgrep]="The finding is a code pattern that matches a known security or correctness rule. Read the matched code and the rule ID. Fix the flagged pattern."
    [ty]="Read the file at the reported line. Fix type errors — check annotations, return types, and argument types."
    [interrogate]="The reported module or function is missing a docstring. Add a one-line docstring to each flagged public function/class/module."
    [style-guide]="CLI output formatting must follow the style guide: section headings use emoji + click.style(ALL CAPS text, fg=COLOR, bold=True). No ASCII splitter lines."
    [semver-format]="The version string in ${VERSION_FILE} does not follow semver 2.0 format (MAJOR.MINOR.PATCH[-prerelease][+build]). Read ${VERSION_FILE} and fix the version field to match semver 2.0. See https://semver.org for the specification."
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

run_check() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1) || fail "$name" "$cmd" "$OUTPUT"
}

run_check_nonempty() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1)
    [ -n "$OUTPUT" ] && fail "$name" "$cmd" "$OUTPUT"
}

# Sync dependencies once upfront
${PACKAGE_MANAGER_SYNC}

# Checks ordered by speed and likelihood of failure.
# EXAMPLE CHECKS: Replace tool commands with researched alternatives.
# Keep the run_check/run_check_nonempty pattern and [check:*] markers.
# [check:pytest]
run_check        "pytest"         ${PACKAGE_MANAGER_RUN} pytest -x --tb=short
# [check:coverage]
run_check        "coverage"       ${PACKAGE_MANAGER_RUN} pytest --cov=${SOURCE_DIR} --cov-report=term --cov-fail-under=${COVERAGE_THRESHOLD} -q
# [check:ruff-lint]
run_check        "ruff check"     ${PACKAGE_MANAGER_RUN} ruff check ${SOURCE_DIR} ${TEST_DIR}
# [check:ruff-format]
run_check        "ruff format"    ${PACKAGE_MANAGER_RUN} ruff format --check ${SOURCE_DIR} ${TEST_DIR}
# [check:pyright]
run_check        "pyright"        ${PACKAGE_MANAGER_RUN} pyright ${SOURCE_DIR}
# [check:mypy]
run_check        "mypy"           ${PACKAGE_MANAGER_RUN} mypy ${SOURCE_DIR}
# [check:bandit]
run_check        "bandit"         ${PACKAGE_MANAGER_RUN} bandit -r ${SOURCE_DIR} -q -ll
# [check:vulture]
run_check_nonempty "vulture"      ${PACKAGE_MANAGER_RUN} vulture ${SOURCE_DIR} --min-confidence ${VULTURE_CONFIDENCE}
# [check:xenon]
run_check        "xenon"          ${PACKAGE_MANAGER_RUN} xenon --max-absolute ${COMPLEXITY_GRADE} --max-modules A --max-average A ${SOURCE_DIR}
# [check:refurb]
run_check_nonempty "refurb"       ${PACKAGE_MANAGER_RUN} refurb ${SOURCE_DIR} --python-version ${PYTHON_VERSION}
# [check:import-linter]
run_check        "import-linter"  ${PACKAGE_MANAGER_RUN} lint-imports
# [check:semgrep]
run_check_nonempty "semgrep"      ${PACKAGE_MANAGER_RUN} semgrep scan --config p/python --error --quiet ${SOURCE_DIR}
# [check:ty]
run_check        "ty"             ${PACKAGE_MANAGER_RUN} ty check ${SOURCE_DIR}
# [check:interrogate]
run_check        "interrogate"    ${PACKAGE_MANAGER_RUN} interrogate ${SOURCE_DIR} -v --fail-under ${DOCSTRING_THRESHOLD} -e ${TEST_DIR}
# [check:style-guide]
run_check        "style-guide"    "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/style-guide-check.sh"

# [check:semver-format]
CURRENT_VERSION=$(${VERSION_EXTRACT_CMD} 2>/dev/null)
if [ -n "$CURRENT_VERSION" ]; then
    SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-([0-9A-Za-z-]+\.)*[0-9A-Za-z-]+)?(\+([0-9A-Za-z-]+\.)*[0-9A-Za-z-]+)?$'
    if ! echo "$CURRENT_VERSION" | grep -qE "$SEMVER_RE"; then
        fail "semver-format" "${VERSION_EXTRACT_CMD}" "Version '${CURRENT_VERSION}' is not valid semver 2.0."
    fi
fi

debuglog "=== ALL CHECKS PASSED ==="
exit 0
