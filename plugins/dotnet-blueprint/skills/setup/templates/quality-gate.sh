#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below are current best-in-class
# choices for .NET projects. The setup skill should research and substitute the
# best tools for each ROLE based on the project's ecosystem. What matters is the
# PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${SOLUTION_FILE}         — solution file path (e.g., "MyApp.sln")
#   ${SOURCE_PROJECTS}       — space-separated source project paths
#   ${TEST_PROJECTS}         — space-separated test project paths
#   ${SOURCE_DIR}            — source directory (e.g., "src/")
#   ${TEST_DIR}              — test directory (e.g., "tests/")
#   ${COVERAGE_THRESHOLD}    — minimum coverage percentage (e.g., 80)
#   ${COMPLEXITY_THRESHOLD}  — max cyclomatic complexity (e.g., 10)
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
# EXAMPLE HINTS: These are for .NET tools. When substituting different tools,
# write hints that are SPECIFIC to that tool — tell Claude which file to read,
# how to re-check, and what to fix.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [dotnet-test]="Read the failing test file and the source it tests. Run 'dotnet test ${TEST_DIR}<project> --filter <TestName>' to see the full error. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run 'dotnet test ${TEST_DIR}<project> --collect:\"XPlat Code Coverage\"' and check the coverage report. Add tests for the uncovered code paths in the source projects."
    [dotnet-format]="Run 'dotnet format ${SOLUTION_FILE} --include <file>' to auto-fix formatting. Check .editorconfig rules if the fix doesn't apply. Read the file at the reported location."
    [dotnet-build]="Read the file at the reported line and column number. Fix the compiler error or analyzer warning. Run 'dotnet build ${SOURCE_DIR}<project>/<project>.csproj --no-restore' to re-check a single project after fixing."
    [dotnet-build-analyzers]="Read the file at the reported line number. The warning/error is from a Roslyn analyzer. Check the rule ID (e.g., CA1234, IDE0001) for guidance. Fix the code pattern or suppress with justification."
    [security-audit]="Run 'dotnet list ${SOLUTION_FILE} package --vulnerable --include-transitive' to see all vulnerable packages. Update the affected package version in Directory.Packages.props or the .csproj file."
    [architecture]="Check the architecture test project for the failing rule. The error shows which dependency violates the declared architecture. Fix by restructuring the code or adjusting the architecture rule if the dependency is intentional."
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

# Restore packages once upfront
dotnet restore ${SOLUTION_FILE} --verbosity quiet

# Checks ordered by speed and likelihood of failure.
# EXAMPLE CHECKS: Replace tool commands with researched alternatives.
# Keep the run_check/run_check_nonempty pattern and [check:*] markers.

# [check:dotnet-build]
run_check        "dotnet-build"         dotnet build ${SOLUTION_FILE} --no-restore --verbosity quiet -warnaserror
# [check:dotnet-test]
run_check        "dotnet-test"          dotnet test ${SOLUTION_FILE} --no-build --verbosity quiet
# [check:coverage]
run_check        "coverage"             dotnet test ${SOLUTION_FILE} --no-build --collect:"XPlat Code Coverage" --verbosity quiet -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=cobertura
# [check:dotnet-format]
run_check        "dotnet-format"        dotnet format ${SOLUTION_FILE} --verify-no-changes --verbosity quiet
# [check:security-audit]
run_check        "security-audit"       dotnet list ${SOLUTION_FILE} package --vulnerable --include-transitive
# [check:architecture]
# run_check      "architecture"         dotnet test ${TEST_DIR}<arch-test-project> --no-build --verbosity quiet

debuglog "=== ALL CHECKS PASSED ==="
exit 0
