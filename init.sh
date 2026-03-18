#!/usr/bin/env bash
set -euo pipefail

# Initialize an agent pipeline in a target directory
# Usage: init.sh [target-directory]
# If no target is given, uses current working directory.

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Initializing agent pipeline in: $TARGET_DIR"

# Don't re-init if already set up
if [ -f "$TARGET_DIR/pipeline.yaml" ]; then
    echo "Error: pipeline.yaml already exists in $TARGET_DIR. Aborting."
    exit 1
fi

# Create directory structure
mkdir -p "$TARGET_DIR"/{artifacts,forum/{open,closed},templates}
mkdir -p "$TARGET_DIR"/agents/{operator,architect}
mkdir -p "$TARGET_DIR"/messages/operator/{pending,active,done}
mkdir -p "$TARGET_DIR"/messages/architect/{pending,active,done}
mkdir -p "$TARGET_DIR"/scripts
mkdir -p "$TARGET_DIR"/.claude/agents

# Copy framework files
cp "$FRAMEWORK_DIR/framework.md" "$TARGET_DIR/"
cp "$FRAMEWORK_DIR/pipeline.yaml" "$TARGET_DIR/"
cp "$FRAMEWORK_DIR/scripts/"*.sh "$TARGET_DIR/scripts/"
cp "$FRAMEWORK_DIR/templates/"* "$TARGET_DIR/templates/"
cp "$FRAMEWORK_DIR/agents/operator/agent.yaml" "$TARGET_DIR/agents/operator/"
cp "$FRAMEWORK_DIR/agents/architect/agent.yaml" "$TARGET_DIR/agents/architect/"
cp "$FRAMEWORK_DIR/.claude/agents/"*.md "$TARGET_DIR/.claude/agents/"

chmod +x "$TARGET_DIR/scripts/"*.sh

echo "Done. Pipeline initialized with operator and architect agents."
echo ""
echo "Next steps:"
echo "  1. Start a session with the architect to add pipeline agents"
echo "  2. Run scripts/run_scheduler.sh to process pending work"
