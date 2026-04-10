#!/usr/bin/env bash
# SessionStart hook: daily plugin update check
# Checks all installed plugins once per 24h, auto-fixes superpowers symlinks if updated.

STAMP="$HOME/.claude/.plugin-check-ts"
SUPERPOWERS_CACHE="$HOME/.claude/plugins/cache/superpowers-marketplace/superpowers"

# Only check once per 24h
NOW=$(date +%s)
if [[ -f "$STAMP" ]]; then
    LAST=$(cat "$STAMP")
    if (( NOW - LAST < 86400 )); then
        exit 0
    fi
fi
echo "$NOW" > "$STAMP"

UPDATED=()
SUPERPOWERS_UPDATED=false

# Get list of all installed plugins and try to update each
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*"❯ "(.+)$ ]]; then
        PLUGIN="${BASH_REMATCH[1]}"
        RESULT=$(claude plugin update "$PLUGIN" 2>&1)
        if ! echo "$RESULT" | grep -q "already at the latest"; then
            UPDATED+=("$PLUGIN")
            [[ "$PLUGIN" == superpowers@* ]] && SUPERPOWERS_UPDATED=true
        fi
    fi
done < <(claude plugin list 2>/dev/null)

# Auto-fix superpowers skill symlinks if plugin was updated
if [[ "$SUPERPOWERS_UPDATED" == true && -d "$SUPERPOWERS_CACHE" ]]; then
    LATEST=$(ls -1 "$SUPERPOWERS_CACHE" 2>/dev/null | sort -V | tail -1)
    if [[ -n "$LATEST" && -d "$SUPERPOWERS_CACHE/$LATEST/skills" ]]; then
        for skill_dir in "$SUPERPOWERS_CACHE/$LATEST/skills"/*/; do
            ln -sfn "$skill_dir" "$HOME/.claude/skills/$(basename "$skill_dir")"
        done
    fi
fi

# Output to Claude context only if something changed
if [[ ${#UPDATED[@]} -gt 0 ]]; then
    echo "=== PLUGIN UPDATES ==="
    echo "Updated: ${UPDATED[*]}"
    [[ "$SUPERPOWERS_UPDATED" == true ]] && echo "Superpowers skills relinked → $LATEST"
    echo "=== END PLUGIN UPDATES ==="
fi

exit 0
