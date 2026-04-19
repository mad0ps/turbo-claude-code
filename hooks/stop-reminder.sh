#!/usr/bin/env bash
# Stop hook: context warning box + git session summary + remind to run /finish.
# Output to stderr — shown to user, not injected into Claude context.

# Read stdin JSON (Claude Code passes session_id, transcript_path, etc.)
stdin_json=$(cat)
session_id=$(printf '%s' "$stdin_json" | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("session_id",""))' 2>/dev/null)

# === Context pct from statusline state file ===
ctx_pct=""
if [[ -n "$session_id" ]]; then
    state_file="$HOME/.claude/state/context-pct-$session_id"
    if [[ -r "$state_file" ]]; then
        ctx_pct=$(cat "$state_file" 2>/dev/null)
    fi
fi

# === Context warning box (Python handles wide-char width correctly) ===
if [[ -n "$ctx_pct" ]] && [[ "$ctx_pct" =~ ^[0-9]+$ ]]; then
    /usr/bin/python3 - "$ctx_pct" >&2 <<'PYEOF'
import sys, unicodedata

pct = int(sys.argv[1])

RESET = '\033[0m'
BOLD = '\033[1m'
YELLOW = '\033[33m'
RED = '\033[31m'
BRED = '\033[1;31m'

if pct >= 90:
    color, emoji, line1, line2 = BRED, '🔥', f'КОНТЕКСТ: {pct}% — COMPACT СЕЙЧАС!', 'БЕГОМ: /finish clear'
elif pct >= 85:
    color, emoji, line1, line2 = RED, '🚨', f'КОНТЕКСТ: {pct}% — compact близко', 'ЗАПУСТИ: /finish clear'
elif pct >= 80:
    color, emoji, line1, line2 = YELLOW, '⚠️', f'Контекст: {pct}% — скоро compact', 'Рекомендую: /finish'
else:
    sys.exit(0)

def wcwidth(ch):
    # Emoji presentation and East Asian wide chars render as 2 cols
    if unicodedata.east_asian_width(ch) in ('W', 'F'):
        return 2
    cp = ord(ch)
    # Common emoji blocks (not covered by east_asian_width)
    if (0x1F300 <= cp <= 0x1FAFF) or (0x2600 <= cp <= 0x27BF) or cp == 0x26A0:
        return 2
    # Combining marks / VS16 etc.
    if unicodedata.category(ch) in ('Mn', 'Me', 'Cf'):
        return 0
    return 1

def vwidth(s):
    return sum(wcwidth(c) for c in s)

INNER = 42  # columns between ║ and ║
EMOJI_COL = 2
GAP = 2  # spaces between emoji and text

def pad(text, width):
    return text + ' ' * max(0, width - vwidth(text))

top    = '╔' + '═' * INNER + '╗'
bottom = '╚' + '═' * INNER + '╝'

# Line 1: "  <emoji>  <text>"  — leading 2sp + emoji(2) + gap(2) = 6 cols of prefix
prefix1 = '  ' + emoji + '  '
text1_width = INNER - vwidth(prefix1)
body1 = prefix1 + BOLD + pad(line1, text1_width) + RESET

# Line 2: "      <text>" — 6 spaces
prefix2 = '      '
text2_width = INNER - vwidth(prefix2)
body2 = prefix2 + pad(line2, text2_width)

print()
print(f'{color}{top}{RESET}')
print(f'{color}║{RESET}{body1}{color}║{RESET}')
print(f'{color}║{RESET}{body2}{color}║{RESET}')
print(f'{color}{bottom}{RESET}')
print()
PYEOF
fi

# === Git session summary ===
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
