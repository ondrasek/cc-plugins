#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, outputs its full stderr/stdout.
# Exit 2 feeds stderr to Claude for automatic fixing.
#
# THIS IS AN ANNOTATED EXAMPLE. The specific tools below (cargo clippy, cargo-llvm-cov,
# cargo-audit, cargo-deny, cargo-machete) are current best-in-class choices for Rust.
# The setup skill should research and substitute the best tools for each ROLE
# based on the project's ecosystem. What matters is the PATTERN:
#   - run_check / run_check_nonempty functions
#   - fail() output format (check name, command, tool output, hint, action directive)
#   - Fail-fast: exit 2 on first failure, one error at a time
#   - TOOL_HINTS: per-tool diagnostic hints that tell Claude how to fix
#   - Check ordering: fastest/most-likely-to-fail first
#
# TEMPLATE VARIABLES (replaced by setup skill):
#   ${WORKSPACE_FLAG}          — workspace flag (e.g., "--workspace" or empty)
#   ${SOURCE_CRATES}           — space-separated source crate names
#   ${COVERAGE_THRESHOLD}      — minimum coverage percentage (e.g., 75)
#   ${COMPLEXITY_THRESHOLD}    — max cognitive complexity (e.g., 25)
#   ${WASM_TARGETS}            — WASM target triple (e.g., "wasm32-unknown-unknown")
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

# Per-tool diagnostic hints for Claude auto-fix.
# EXAMPLE HINTS: These are for the Rust tools shown below. When substituting
# different tools, write hints that are SPECIFIC to that tool — tell Claude
# which file to read, how to re-check a single crate, and what to fix.
declare -A TOOL_HINTS
TOOL_HINTS=(
    [cargo-test]="Read the failing test and the source it tests. Run 'cargo test -p <crate> <test_name> -- --nocapture' to see the full output. Fix the source code, not the test, unless the test itself is wrong."
    [coverage]="Run 'cargo llvm-cov ${WORKSPACE_FLAG} --text' to see which lines are uncovered. Add tests for the uncovered code paths."
    [clippy]="Read the file at the reported line number. Clippy errors usually have a suggested fix in the help message. Apply the suggestion or restructure the code. Run 'cargo clippy -p <crate>' to re-check a single crate after fixing."
    [cargo-fmt]="Run 'cargo fmt' to auto-fix all formatting issues. If specific files need attention, check the diff output for the affected lines."
    [cargo-audit]="Run 'cargo audit' to see full advisory details. Update the affected dependency version in Cargo.toml. Run 'cargo update -p <crate>' to update a specific dependency."
    [cargo-deny]="Read the deny.toml configuration and the error message. For license issues, add the license to the allow list or find an alternative crate. For duplicate versions, consolidate dependency versions. For advisories, update the affected crate."
    [cargo-machete]="The reported dependency is declared in Cargo.toml but not used in source code. Remove it from [dependencies] in Cargo.toml. If it's used via a macro or build script, add it to the machete ignore list."
    [cargo-doc]="Add documentation comments (///) to the reported public items. Each public function, struct, enum, and trait should have a doc comment explaining its purpose."
    [wasm-build]="The WASM build failed. Check for platform-specific code that doesn't compile for wasm32. Use cfg attributes to gate platform-specific sections: #[cfg(not(target_arch = \"wasm32\"))]."
    [wasm-test]="Read the failing WASM test. Run 'wasm-pack test --node' or 'wasm-pack test --headless --chrome' to see the full output. Fix the source code to work correctly in the WASM environment."
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
# [check:cargo-test]
run_check        "cargo-test"     cargo test ${WORKSPACE_FLAG} -- --no-fail-fast
# [check:coverage]
run_check        "coverage"       cargo llvm-cov ${WORKSPACE_FLAG} --fail-under-lines ${COVERAGE_THRESHOLD}
# [check:clippy]
run_check        "clippy"         cargo clippy ${WORKSPACE_FLAG} -- -D warnings
# [check:cargo-fmt]
run_check        "cargo-fmt"      cargo fmt ${WORKSPACE_FLAG} --check
# [check:cargo-audit]
run_check        "cargo-audit"    cargo audit
# [check:cargo-deny]
run_check        "cargo-deny"     cargo deny check
# [check:cargo-machete]
run_check_nonempty "cargo-machete" cargo machete
# [check:cargo-doc]
run_check        "cargo-doc"      cargo doc ${WORKSPACE_FLAG} --no-deps 2>&1 | grep -v "^$"
# [check:wasm-build]
# run_check      "wasm-build"     cargo build --target ${WASM_TARGETS}
# [check:wasm-test]
# run_check      "wasm-test"      wasm-pack test --node

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
