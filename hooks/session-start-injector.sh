#!/usr/bin/env bash
# SessionStart hook: inject persistent context into every Claude session.
# Injects: handoff.md (neuro-cortex) + project CHECKPOINT + project MEMORY.md + global todo.md

CORTEX_DIR="$HOME/Documents/pr0j3cts/neuro-cortex"
HANDOFF="$CORTEX_DIR/handoff.md"
GLOBAL_TODO="$HOME/.claude/notes/todo.md"
VAULT_DIR="${CLAUDE_VAULT_DIR:-$HOME/Documents/pr0j3cts/_vault}"

# Find .context/MEMORY.md by walking up from CWD (up to 3 levels)
# Also capture the project root (parent of .context/) to resolve checkpoint file.
CWD="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MEMORY_FILE=""
PROJECT_ROOT=""
search_dir="$CWD"
for i in 1 2 3; do
    if [[ -f "$search_dir/.context/MEMORY.md" ]]; then
        MEMORY_FILE="$search_dir/.context/MEMORY.md"
        PROJECT_ROOT="$search_dir"
        break
    fi
    search_dir="$(dirname "$search_dir")"
done

# Derive project slug for checkpoint lookup (same rule as pre-compact-snapshot.sh)
CHECKPOINT_FILE=""
if [[ -n "$PROJECT_ROOT" ]]; then
    project_raw=$(basename "$PROJECT_ROOT")
    project_slug=$(printf '%s' "$project_raw" | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
    primary="$VAULT_DIR/raw/sessions/checkpoint-${project_slug}.md"
    fallback="$VAULT_DIR/raw/sessions/checkpoint-${project_slug}-auto.md"
    if [[ -f "$primary" ]]; then
        CHECKPOINT_FILE="$primary"
    elif [[ -f "$fallback" ]]; then
        CHECKPOINT_FILE="$fallback"
    fi
fi

# Sync neuro-cortex with GitHub (silent, best-effort)
if [[ -d "$CORTEX_DIR/.git" ]]; then
    git -C "$CORTEX_DIR" pull --ff-only --quiet 2>/dev/null || true
fi

echo "=== SESSION CONTEXT ==="
echo "Date: $(date '+%Y-%m-%d %H:%M')"
echo ""

if [[ -f "$HANDOFF" ]]; then
    echo "--- HANDOFF ---"
    cat "$HANDOFF"
    echo ""
fi

if [[ -n "$CHECKPOINT_FILE" ]]; then
    echo "--- CHECKPOINT ($CHECKPOINT_FILE) ---"
    cat "$CHECKPOINT_FILE"
    echo ""
fi

if [[ -n "$MEMORY_FILE" ]]; then
    echo "--- PROJECT MEMORY ($MEMORY_FILE) ---"
    tail -50 "$MEMORY_FILE"
    echo ""
fi

if [[ -f "$GLOBAL_TODO" ]]; then
    echo "--- GLOBAL TASKS ---"
    cat "$GLOBAL_TODO"
    echo ""
fi

echo "=== END SESSION CONTEXT ==="
exit 0
