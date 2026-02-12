#!/bin/bash
set -e

# Config
LUCY_IMAGE="${LUCY_IMAGE:-fifty-first-contexts:latest}"
LUCY_AGENT="${LUCY_AGENT:-}"
LUCY_PROMPT="${LUCY_PROMPT:-prompt.md}"
MAX_ITERATIONS="${MAX_ITERATIONS:-10}"

# Auth directory (OS-specific)
if [[ "$OSTYPE" == darwin* ]]; then
    AUTH_DIR="${AUTH_DIR:-$HOME/Library/Application Support/kiro-cli}"
else
    AUTH_DIR="${AUTH_DIR:-$HOME/.local/share/kiro-cli}"
fi

KIRO_DIR="${KIRO_DIR:-$HOME/.kiro}"
WORK_DIR="${WORK_DIR:-$(pwd)}"

# SSH (agent forwarding preferred)
SSH_SOCK="${SSH_AUTH_SOCK:-}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"

# Git identity
GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Lucy Whitmore}"
GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-lucy@whitmore.local}"

run_iteration() {
    local i="$1"
    local vol="lucy-$$-$i"
    
    docker volume create "$vol" >/dev/null
    
    local ssh_args=()
    if [[ -n "$SSH_SOCK" && -S "$SSH_SOCK" ]]; then
        ssh_args+=(-v "$SSH_SOCK:/ssh-agent" -e SSH_AUTH_SOCK=/ssh-agent)
    elif [[ -d "$SSH_DIR" ]]; then
        ssh_args+=(-v "$SSH_DIR:/root/.ssh:ro")
    fi
    
    local agent_args=()
    if [[ -n "$LUCY_AGENT" ]]; then
        agent_args+=(--agent "$LUCY_AGENT")
    fi
    
    local prompt
    prompt=$(cat "$LUCY_PROMPT")
    
    docker run --rm -i \
        -v "$WORK_DIR:/workspace:rw" \
        -w /workspace \
        -v "$vol:/root/.local/share/kiro-cli:rw" \
        -v "$AUTH_DIR:/auth:ro" \
        -v "$KIRO_DIR:/root/.kiro:ro" \
        -e GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
        -e GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
        -e GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" \
        -e GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" \
        "${ssh_args[@]}" \
        "$LUCY_IMAGE" \
        kiro-cli chat --no-interactive --trust-all-tools "${agent_args[@]}" "$prompt" 2>&1 | tee /dev/stderr
    
    local rc="${PIPESTATUS[0]}"
    docker volume rm "$vol" >/dev/null 2>&1 || true
    return "$rc"
}

echo "Starting Lucy - Image: $LUCY_IMAGE - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 "$MAX_ITERATIONS"); do
    echo ""
    echo "==============================================================="
    echo "  Lucy Iteration $i of $MAX_ITERATIONS"
    echo "==============================================================="
    
    OUTPUT=$(run_iteration "$i") || true
    
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "Lucy completed all tasks at iteration $i!"
        exit 0
    fi
    
    echo "Iteration $i complete. Continuing..."
    sleep 2
done

echo ""
echo "Lucy reached max iterations ($MAX_ITERATIONS) without completing."
exit 1
