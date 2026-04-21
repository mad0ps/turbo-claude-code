#!/usr/bin/env bash
# PostToolUse hook: remind to refresh graphify after wiki writes.
#
# When Claude edits _vault/wiki/**, the graph becomes stale — subsequent
# `graphify query` will miss the new facts. We don't auto-run `graphify update .`
# (it's slow, may hit APIs), we just surface a systemMessage.
#
# Response: {"continue": true, "systemMessage": "..."} — always allow,
# just inject a reminder into Claude's context.

HOOK_INPUT="$(cat)" python3 <<'PY'
import json, os, re, sys

raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = data.get("tool_name") or data.get("toolName") or ""
if tool_name not in ("Write", "Edit", "NotebookEdit"):
    sys.exit(0)

tool_input = data.get("tool_input") or data.get("toolInput") or {}
file_path = (
    tool_input.get("file_path")
    or tool_input.get("filePath")
    or tool_input.get("notebook_path")
    or ""
)
if not file_path:
    sys.exit(0)

if not re.search(r"/_vault/wiki/", file_path):
    sys.exit(0)

subpath = file_path.split("/_vault/", 1)[1] if "/_vault/" in file_path else file_path

msg = (
    f"vault: {subpath} changed — graph is now stale.\n"
    "Before running `graphify query` or committing: `cd ~/Documents/pr0j3cts/_vault && graphify update .` "
    "(AST-only, no API cost). Skip if you are about to do more edits."
)

print(json.dumps({"continue": True, "systemMessage": msg}))
sys.exit(0)
PY
