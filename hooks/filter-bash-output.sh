#!/usr/bin/env bash
# PostToolUse hook: truncate large bash outputs to save tokens.

input=$(cat)

result=$(echo "$input" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
except Exception:
    print('{\"continue\": true}')
    sys.exit(0)

if data.get('tool_name') != 'Bash':
    print('{\"continue\": true}')
    sys.exit(0)

try:
    MAX_LINES = 200
    TAIL_LINES = 50
    output = data.get('tool_response') or data.get('tool_output', {})
    if isinstance(output, str):
        stdout = output
    elif isinstance(output, dict):
        stdout = output.get('stdout', output.get('output', ''))
    else:
        stdout = ''
    lines = stdout.split('\n')
    total = len(lines)
    if total > MAX_LINES:
        head = lines[:MAX_LINES - TAIL_LINES]
        tail = lines[-TAIL_LINES:]
        truncated = '\n'.join(head) + '\n\n... [' + str(total - MAX_LINES) + ' lines truncated] ...\n\n' + '\n'.join(tail)
        print(json.dumps({'continue': True, 'toolResponse': {'stdout': truncated, 'stderr': ''}}))
    else:
        print('{\"continue\": true}')
except Exception:
    print('{\"continue\": true}')
" 2>/dev/null || echo '{"continue": true}')

if [[ -n "$result" ]]; then
    printf '%s\n' "$result"
else
    printf '{"continue": true}\n'
fi
