#!/bin/bash
# Apply the python-blueprint to the current project.
# Invokes Claude Code to perform a smart merge of blueprint files.
#
# Usage:
#   cd your-project
#   .blueprint/apply.sh
#
# Prerequisites:
#   - Claude Code CLI installed (https://claude.ai/install.sh)
#   - This repo added as a git submodule at .blueprint/

set -euo pipefail

BLUEPRINT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$BLUEPRINT_DIR/.." && pwd)"

# Check for Claude Code CLI
if ! command -v claude &>/dev/null; then
    echo "Error: Claude Code CLI is not installed."
    echo ""
    echo "Install it with:"
    echo "  curl -fsSL https://claude.ai/install.sh | bash"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

# Read the merge prompt
PROMPT_FILE="$BLUEPRINT_DIR/APPLY_PROMPT.md"
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: APPLY_PROMPT.md not found at $PROMPT_FILE"
    exit 1
fi

PROMPT=$(cat "$PROMPT_FILE")

echo "Applying python-blueprint to: $PROJECT_DIR"
echo "Blueprint source: $BLUEPRINT_DIR"
echo ""

# Invoke Claude Code with the merge prompt
cd "$PROJECT_DIR"
claude -p "$PROMPT" --allowedTools "Edit,Write,Read,Glob,Grep,Bash"
