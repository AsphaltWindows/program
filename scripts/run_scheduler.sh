#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PIPELINE="$ROOT_DIR/pipeline.yaml"
LOCK_DIR="$ROOT_DIR/.locks"

mkdir -p "$LOCK_DIR"

while true; do

# Parse scheduled agent names from pipeline.yaml (skip agents with scheduled: false)
AGENTS=""
CURRENT_AGENT=""
IS_SCHEDULED=true

while IFS= read -r line; do
    if echo "$line" | grep -q '^\s*-\?\s*name:'; then
        if [ -n "$CURRENT_AGENT" ] && [ "$IS_SCHEDULED" = true ]; then
            AGENTS="$AGENTS $CURRENT_AGENT"
        fi
        CURRENT_AGENT=$(echo "$line" | sed 's/.*name:\s*//' | tr -d ' ')
        IS_SCHEDULED=true
    elif echo "$line" | grep -q '^\s*scheduled:\s*false'; then
        IS_SCHEDULED=false
    fi
done < "$PIPELINE"
if [ -n "$CURRENT_AGENT" ] && [ "$IS_SCHEDULED" = true ]; then
    AGENTS="$AGENTS $CURRENT_AGENT"
fi

if [ -z "$AGENTS" ]; then
    echo "No agents defined in pipeline.yaml"
    exit 0
fi

for AGENT in $AGENTS; do
    LOCK_FILE="$LOCK_DIR/${AGENT}.pid"

    # Check if agent is already running
    if [ -f "$LOCK_FILE" ]; then
        PID=$(cat "$LOCK_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "[$AGENT] Already running (PID $PID), skipping."
            continue
        else
            echo "[$AGENT] Stale lock file found, removing."
            rm -f "$LOCK_FILE"
        fi
    fi

    HAS_WORK=false

    # Check forum topics without this agent's close-vote
    for TOPIC in "$ROOT_DIR"/forum/open/*.md; do
        [ -f "$TOPIC" ] || continue
        if ! grep -q "^VOTE:${AGENT}$" "$TOPIC"; then
            HAS_WORK=true
            break
        fi
    done

    # Check pending messages
    if [ "$HAS_WORK" = false ]; then
        PENDING_DIR="$ROOT_DIR/messages/${AGENT}/pending"
        if [ -d "$PENDING_DIR" ] && ls "$PENDING_DIR"/*.md &>/dev/null; then
            HAS_WORK=true
        fi
    fi

    if [ "$HAS_WORK" = false ]; then
        echo "[$AGENT] No pending work."
        continue
    fi

    echo "[$AGENT] Work found, launching."

    # Read agent type to determine how to launch
    AGENT_TYPE=$(grep '^\s*type:' "$ROOT_DIR/agents/${AGENT}/agent.yaml" | sed 's/.*type:\s*//' | tr -d ' ')

    # Agent prompt lives in .claude/agents/
    PROMPT_FILE="$ROOT_DIR/.claude/agents/${AGENT}.md"

    if [ ! -f "$PROMPT_FILE" ]; then
        echo "[$AGENT] No .claude/agents/${AGENT}.md found, skipping."
        continue
    fi

    # Launch agent in background
    (
        echo "$$" > "$LOCK_FILE"

        echo "[$AGENT] Launching (type: $AGENT_TYPE)..."

        # --- AGENT LAUNCH COMMAND ---
        # Replace this with your LLM invocation.
        # The agent should receive:
        #   1. Its system prompt (.claude/agents/{name}.md)
        #   2. Access to the ROOT_DIR for reading artifacts, messages, and forum topics
        #
        # The agent is responsible for finding its own work:
        #   - Check forum/open/ for topics needing its attention
        #   - Check messages/{name}/pending/ for pending messages
        #   - Process work in priority order (forum first, then messages)
        #   - Move messages through pending/ -> active/ -> done/
        #
        # Example (placeholder):
        # your-llm-cli --system-prompt "$PROMPT_FILE" --root "$ROOT_DIR"
        echo "[$AGENT] TODO: Invoke LLM agent here with prompt=$PROMPT_FILE"

        rm -f "$LOCK_FILE"
    ) &

done

echo "Scheduler pass complete."
sleep 20
done
