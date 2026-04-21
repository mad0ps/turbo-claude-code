#!/usr/bin/env bash
# PreToolUse hook: enforce `graphify query` before Read on _vault/{raw,wiki}/**
#
# Philosophy: Khan built graphify specifically to stop Claude from burning tokens
# on Read raw/*.md. This hook blocks direct Read inside the vault unless a recent
# `graphify query` call is present in the transcript, or escape env VAULT_DIRECT_READ=1.
#
# Response format (modern PreToolUse):
#   allow → exit 0, no output
#   block → print {"continue": false, "stopReason": "..."} and exit 0

HOOK_INPUT="$(cat)" HOOK_ESCAPE="${VAULT_DIRECT_READ:-0}" python3 <<'PY'
import json, os, re, sys
from pathlib import Path

raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = data.get("tool_name") or data.get("toolName") or ""
if tool_name != "Read":
    sys.exit(0)

tool_input = data.get("tool_input") or data.get("toolInput") or {}
file_path = tool_input.get("file_path") or tool_input.get("filePath") or ""
if not file_path:
    sys.exit(0)

m = re.search(r"/_vault/(raw|wiki)/", file_path)
if not m:
    sys.exit(0)

if os.environ.get("HOOK_ESCAPE") == "1":
    sys.exit(0)

transcript_path = data.get("transcript_path") or data.get("transcriptPath") or ""
if transcript_path and Path(transcript_path).exists():
    try:
        with open(transcript_path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 200_000))
            tail = f.read().decode("utf-8", errors="ignore")
        if re.search(r"graphify\s+(query|path|explain)\b", tail):
            sys.exit(0)
    except Exception:
        pass

subpath = file_path.split("/_vault/", 1)[1] if "/_vault/" in file_path else file_path

msg = (
    f"Vault Read blocked: {subpath}\n"
    "Rule: use `graphify query \"...\"` (or path/explain) first — that's why graphify exists.\n"
    "  • broad:   graphify query \"your question\"\n"
    "  • focused: graphify query \"...\" --dfs --budget 3000\n"
    "  • link:    graphify path \"A\" \"B\"\n"
    "  • node:    graphify explain \"NodeName\"\n"
    "Escape (only if query returned nothing useful): set VAULT_DIRECT_READ=1 in env."
)

print(json.dumps({
    "continue": False,
    "stopReason": msg,
    "decision": "block",
    "reason": msg,
}))
sys.exit(0)
PY
