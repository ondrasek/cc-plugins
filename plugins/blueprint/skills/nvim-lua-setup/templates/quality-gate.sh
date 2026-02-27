#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below (selene, stylua,
# lua-language-server, lizard) are current best-in-class choices for Neovim Lua.
# The setup skill should research and substitute the best tools for each ROLE
# based on the project's ecosystem. What matters is the PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${SOURCE_DIR}              — main source directory (e.g., "lua/")
#   ${TEST_DIR}                — test directory (e.g., "tests/")
#   ${TEST_COMMAND}            — full test invocation command
#   ${COVERAGE_THRESHOLD}      — minimum coverage percentage (e.g., 75)
#   ${COMPLEXITY_THRESHOLD}    — max cyclomatic complexity (e.g., 10)
#   ${PLUGIN_NAME}             — plugin name for coverage filtering
#   ${VERSION_FILE}            — path to version file (e.g., "myplugin-scm-1.rockspec")
#   ${VERSION_EXTRACT_CMD}     — command to extract version from file on disk
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
# EXAMPLE HINTS: These are for Neovim Lua tools. When substituting
# different tools, write hints that are SPECIFIC to that tool.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [test]="Read the failing test and the source it tests. Run the individual test file to see the full output. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run luacov and check the report to see which lines are uncovered. Add tests for the uncovered code paths in ${TEST_DIR}."
    [selene]="Read the file at the reported line number. Selene errors include the lint rule name in brackets. Fix the issue or add a '-- selene: allow(rule_name)' comment if it's a false positive. Run 'selene ${SOURCE_DIR}<module>/' to re-check a single module after fixing."
    [stylua]="Run 'stylua ${SOURCE_DIR}' to auto-fix all formatting issues. If stylua reports a syntax error, fix the Lua syntax first."
    [lua-language-server]="Read the file at the reported line. Add or fix LuaCATS type annotations (---@param, ---@return, ---@type). Run 'lua-language-server --check ${SOURCE_DIR}' to re-check after fixing."
    [lizard]="The reported function exceeds the complexity threshold. Split it into smaller functions or simplify the control flow. Extract conditional blocks into helper functions."
    [security]="The reported pattern may be a security concern. If the pattern is intentional (e.g., CLI wrapper plugin), add a comment explaining why. Otherwise, replace with a safer alternative."
    [doc]="Create a doc/ directory with a vimdoc help file (doc/<plugin_name>.txt). Use :help write-plugin for the vimdoc format reference."
    [structure]="Move logic from plugin/ files into lua/${PLUGIN_NAME}/ modules. Plugin/ files should only contain require() calls and vim.api.nvim_create_user_command() registrations."
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

# Checks ordered by speed and likelihood of failure.
# EXAMPLE CHECKS: Replace tool commands with researched alternatives.
# Keep the run_check/run_check_nonempty pattern and [check:*] markers.

# [check:test]
run_check        "test"           ${TEST_COMMAND}
# [check:coverage]
# run_check      "coverage"       luacov && awk '/^Summary/ {getline; if ($NF+0 < ${COVERAGE_THRESHOLD}) exit 1}' luacov.report.out
# [check:selene]
run_check        "selene"         selene ${SOURCE_DIR}
# [check:stylua]
run_check        "stylua"         stylua --check ${SOURCE_DIR}
# [check:lua-language-server]
# run_check      "lua-language-server"  lua-language-server --check ${SOURCE_DIR}
# [check:lizard]
run_check        "lizard"         lizard ${SOURCE_DIR} --CCN ${COMPLEXITY_THRESHOLD} --warnings_only
# [check:security]
# Grep-based check for dangerous patterns
SECURITY_OUTPUT=$(grep -rnE '(os\.execute|io\.popen|loadstring|load\s*\(.*["\x27])' ${SOURCE_DIR} 2>/dev/null || true)
if [ -n "$SECURITY_OUTPUT" ]; then
    debuglog "Security warnings (non-blocking): $SECURITY_OUTPUT"
    # Non-blocking by default — uncomment to enforce:
    # fail "security" "grep dangerous patterns" "$SECURITY_OUTPUT"
fi
# [check:doc]
if [ ! -d "doc" ] || [ -z "$(find doc -name '*.txt' 2>/dev/null)" ]; then
    fail "doc" "check doc/ directory" "No vimdoc help files found. Expected doc/*.txt files."
fi
# [check:structure]
for f in plugin/*.lua; do
    [ -f "$f" ] || continue
    LINES=$(wc -l < "$f" | tr -d ' ')
    if [ "$LINES" -gt 30 ]; then
        fail "structure" "check plugin/ file sizes" "File $f has $LINES lines (max 30). Plugin/ files should be entry points only — move logic to ${SOURCE_DIR}."
    fi
done

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
