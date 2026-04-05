#!/usr/bin/env bash
# Stop hook: remind user to run /finish before ending session.
# Outputs to stderr so it shows in terminal but doesn't interfere with tool protocol.
echo '{"decision":"allow"}'
echo "[*] Run /finish to save progress and extract learnings" >&2
