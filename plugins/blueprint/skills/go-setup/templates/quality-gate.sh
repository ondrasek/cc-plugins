#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below are current best-in-class
# choices for Go. The setup skill should research and substitute the best tools for
# each ROLE based on the project's ecosystem. What matters is the PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${MODULE_PATH}             — Go module path from go.mod
#   ${COVERAGE_THRESHOLD}      — minimum coverage percentage (e.g., 80)
#   ${CYCLOMATIC_THRESHOLD}    — max cyclomatic complexity (e.g., 15)
#   ${COGNITIVE_THRESHOLD}     — max cognitive complexity (e.g., 20)
#
# ENABLED CHECKS (setup skill removes disabled ones and adds researched tools):
#   Each check is guarded by a comment marker for easy removal.

set -o pipefail

HOOK_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log"
WORKTREE_ID="$(basename "${CLAUDE_PROJECT_DIR:-.}")"
debuglog() {
    echo "[quality-gate@${WORKTREE_ID}] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

cd "${CLAUDE_PROJECT_DIR:-.}"

# Per-tool diagnostic hints for Claude auto-fix.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [go-test]="Read the failing test and the source it tests. Run 'go test -v -run TestName ./pkg/...' to see the full output. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run 'go tool cover -func=coverage.out' to see which functions are uncovered. Add tests for the uncovered code paths. Use '-coverpkg=./...' to include cross-package coverage."
    [golangci-lint]="Read the file at the reported line. The linter name is shown in brackets. Run 'golangci-lint run ./path/to/pkg/...' to re-check a single package after fixing."
    [golangci-fmt]="Run 'golangci-lint fmt ./...' to auto-fix all formatting issues. If specific files need attention, run 'gofumpt -w <file>' directly."
    [govulncheck]="Run 'govulncheck ./...' to see full vulnerability details. Update the affected dependency: 'go get <module>@latest' then 'go mod tidy'."
    [go-mod-verify]="Run 'go mod verify' to check module integrity. If checksums don't match, run 'go mod download' to re-fetch. For persistent issues, delete go.sum and run 'go mod tidy'."
    [go-mod-tidy]="Run 'go mod tidy' to clean up go.mod and go.sum. Check for unused imports in source code that may have kept a dependency alive."
    [deadcode]="The reported function is unreachable from any main or test entry point. Remove it or add a test/usage. Run 'deadcode -filter=${MODULE_PATH} -test ./...' to re-check."
    [semver-format]="The version string in ${VERSION_FILE} does not follow semver 2.0 format (MAJOR.MINOR.PATCH[-prerelease][+build]). Read ${VERSION_FILE} and fix the version constant to match semver 2.0. See https://semver.org for the specification."
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

# Checks ordered by speed and likelihood of failure.
# [check:go-test]
run_check        "go-test"        go test -race -coverprofile=coverage.out -covermode=atomic -count=1 -failfast -shuffle=on ./...
# [check:coverage]
run_check        "coverage"       go-test-coverage --config=.testcoverage.yml
# [check:golangci-lint]
run_check        "golangci-lint"  golangci-lint run ./...
# [check:golangci-fmt]
run_check_nonempty "golangci-fmt" golangci-lint fmt --diff ./...
# [check:govulncheck]
run_check        "govulncheck"    govulncheck ./...
# [check:go-mod-verify]
run_check        "go-mod-verify"  go mod verify
# [check:go-mod-tidy]
# Requires Go 1.21+. For older versions, remove this check or replace with
# 'go mod tidy && git diff --exit-code go.mod go.sum'.
run_check_nonempty "go-mod-tidy"  go mod tidy -diff
# [check:deadcode]
# run_check_nonempty "deadcode"   deadcode -filter=${MODULE_PATH} -test ./...

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
