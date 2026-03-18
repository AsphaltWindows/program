#!/usr/bin/env bash
set -euo pipefail

# Initialize or upgrade an agent pipeline in a target directory
# Usage: init.sh [target-directory]
# If no target is given, uses current working directory.
#
# Fresh install: creates directory structure and copies all framework files.
# Upgrade: copies framework files over existing ones, preserves project-specific
# files (pipeline.yaml, agent definitions, artifacts, messages, forum topics).
# The architect agent handles any pipeline migration after upgrade.

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

IS_UPGRADE=false
if [ -f "$TARGET_DIR/pipeline.yaml" ]; then
    IS_UPGRADE=true
    echo "Upgrading agent pipeline in: $TARGET_DIR"
else
    echo "Initializing agent pipeline in: $TARGET_DIR"
fi

# Create directory structure (idempotent)
mkdir -p "$TARGET_DIR"/{artifacts,forum/{open,closed},templates}
mkdir -p "$TARGET_DIR"/agents/{operator,architect}
mkdir -p "$TARGET_DIR"/messages/operator
mkdir -p "$TARGET_DIR"/messages/architect
mkdir -p "$TARGET_DIR"/scripts
mkdir -p "$TARGET_DIR"/.claude/agents

# Copy framework files (always overwritten — these are framework-owned)
cp "$FRAMEWORK_DIR/framework.md" "$TARGET_DIR/"
cp "$FRAMEWORK_DIR/scripts/"*.sh "$TARGET_DIR/scripts/"
cp -r "$FRAMEWORK_DIR/templates/"* "$TARGET_DIR/templates/"
cp "$FRAMEWORK_DIR/agents/operator/agent.yaml" "$TARGET_DIR/agents/operator/"
cp "$FRAMEWORK_DIR/agents/architect/agent.yaml" "$TARGET_DIR/agents/architect/"
cp "$FRAMEWORK_DIR/.claude/agents/operator.md" "$TARGET_DIR/.claude/agents/operator.md"
cp "$FRAMEWORK_DIR/.claude/agents/architect.md" "$TARGET_DIR/.claude/agents/architect.md"

chmod +x "$TARGET_DIR/scripts/"*.sh

# Only copy pipeline.yaml on fresh install — it's project-owned after that
if [ "$IS_UPGRADE" = false ]; then
    cp "$FRAMEWORK_DIR/pipeline.yaml" "$TARGET_DIR/"
fi

if [ "$IS_UPGRADE" = true ]; then
    echo "Done. Framework files upgraded."
    echo ""
    echo "Next steps:"
    echo "  1. Start a session with the architect to reconcile the pipeline"
    echo "     with any framework changes"
else
    echo "Done. Pipeline initialized with operator and architect agents."
    echo ""
    echo "Next steps:"
    echo "  1. Start a session with the architect to add pipeline agents"
    echo "  2. Run scripts/run_scheduler.sh to process pending work"
fi
