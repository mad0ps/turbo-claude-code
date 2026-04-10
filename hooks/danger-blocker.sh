#!/usr/bin/env bash
# PreToolUse/Bash hook: block dangerous commands before execution.
# Adds friction to irreversible operations — Claude must get explicit user confirmation.

input=$(cat)

BLOCK_REASON=$(echo "$input" | python3 -c "
import sys, json, re

try:
    data = json.load(sys.stdin)
    cmd = data.get('tool_input', {}).get('command', '')
except Exception:
    sys.exit(0)

patterns = [
    (r'rm\s+-[rRfFdv]*[fF][rRdv]*\s+/',        'rm -rf on absolute path'),
    (r'\bDROP\s+(TABLE|DATABASE|SCHEMA)\b',      'DROP TABLE/DATABASE/SCHEMA'),
    (r'git\s+push\s+.*?(-f\b|--force\b)',        'git push --force'),
    (r'git\s+reset\s+--hard',                    'git reset --hard'),
    (r'systemctl\s+(stop|restart)\s+\S+',        'systemctl stop/restart'),
    (r'docker\s+system\s+prune',                 'docker system prune'),
    (r'ssh\s+.*sudo\s+(systemctl|reboot|halt)',  'remote sudo system command'),
]

for pattern, label in patterns:
    if re.search(pattern, cmd, re.IGNORECASE):
        print(label)
        sys.exit(0)
" 2>/dev/null)

if [[ -n "$BLOCK_REASON" ]]; then
    BLOCK_REASON="$BLOCK_REASON" python3 -c "
import json, os
reason = os.environ.get('BLOCK_REASON', 'dangerous command')
print(json.dumps({
    'decision': 'block',
    'reason': 'DANGER ZONE: ' + reason + ' — confirm with user before proceeding'
}))
"
    exit 1
fi

exit 0
