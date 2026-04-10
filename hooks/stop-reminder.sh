#!/usr/bin/env bash
# Stop hook: show git session summary + remind to run /finish.
# Output to stderr — shown to user, not injected into Claude context.

# Walk up from CWD looking for a git repo (max 3 levels)
search_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
git_dir=""
for i in 1 2 3; do
    if git -C "$search_dir" rev-parse --git-dir >/dev/null 2>&1; then
        git_dir="$search_dir"
        break
    fi
    search_dir="$(dirname "$search_dir")"
done

echo "=== Session Summary ===" >&2

if [[ -n "$git_dir" ]]; then
    commits=$(git -C "$git_dir" log --since="$(date +%Y-%m-%d)" --oneline --color=never 2>/dev/null)
    if [[ -n "$commits" ]]; then
        count=$(printf '%s\n' "$commits" | wc -l | tr -d ' ')
        echo "Today's commits ($count):" >&2
        printf '%s\n' "$commits" | while IFS= read -r line; do
            echo "  $line" >&2
        done
    else
        echo "No commits today" >&2
    fi

    status=$(git -C "$git_dir" status --short 2>/dev/null)
    if [[ -n "$status" ]]; then
        echo "" >&2
        echo "Uncommitted changes:" >&2
        printf '%s\n' "$status" | while IFS= read -r line; do
            echo "  $line" >&2
        done
    fi
fi

echo "" >&2
echo "[→] Run /finish to save progress" >&2
exit 0
