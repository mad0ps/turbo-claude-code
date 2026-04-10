#!/usr/bin/env bash
# SessionStart hook: inject persistent context into every Claude session.
# Injects: handoff.md (neuro-cortex) + project MEMORY.md + global todo.md

CORTEX_DIR="$HOME/Documents/pr0j3cts/neuro-cortex"
HANDOFF="$CORTEX_DIR/handoff.md"
GLOBAL_TODO="$HOME/.claude/notes/todo.md"

# Find .context/MEMORY.md by walking up from CWD (up to 3 levels)
CWD="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MEMORY_FILE=""
search_dir="$CWD"
for i in 1 2 3; do
    if [[ -f "$search_dir/.context/MEMORY.md" ]]; then
        MEMORY_FILE="$search_dir/.context/MEMORY.md"
        break
    fi
    search_dir="$(dirname "$search_dir")"
done

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
