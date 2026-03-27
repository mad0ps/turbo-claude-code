#!/usr/bin/env bash
# PostToolUse hook: truncate large bash outputs to save tokens.
# Reads the tool result from stdin (JSON), checks stdout length,
# and truncates if over threshold.
#
# Claude Code hook protocol:
#   stdin  = JSON {"tool_name":"Bash","tool_input":{...},"tool_output":{"stdout":"...","stderr":"..."}}
#   stdout = JSON {"decision":"allow"} or {"decision":"allow","reason":"...","tool_output":{...}}

set -euo pipefail

MAX_LINES=200
TAIL_LINES=50

input=$(cat)

tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")

if [[ "$tool_name" != "Bash" ]]; then
    echo '{"decision":"allow"}'
    exit 0
fi

# Extract stdout, count lines, truncate if needed
result=$(python3 -c "
import sys, json

data = json.load(sys.stdin)
output = data.get('tool_output', {})

# Handle both string and dict tool_output
if isinstance(output, str):
    stdout = output
else:
    stdout = output.get('stdout', '')

lines = stdout.split('\n')
total = len(lines)
max_lines = $MAX_LINES
tail_lines = $TAIL_LINES

if total > max_lines:
    head = lines[:max_lines - tail_lines]
    tail = lines[-tail_lines:]
    truncated = '\n'.join(head) + f'\n\n... [{total - max_lines} lines truncated, showing first {max_lines - tail_lines} + last {tail_lines}] ...\n\n' + '\n'.join(tail)
    print(json.dumps({'decision': 'allow', 'tool_output': truncated}))
else:
    print(json.dumps({'decision': 'allow'}))
" <<< "$input" 2>/dev/null)

if [[ -n "$result" ]]; then
    echo "$result"
else
    echo '{"decision":"allow"}'
fi
