---
name: finish
description: Use when user invokes /finish or ends a session — orchestrates /reflect (extract instincts while context is full) then /save-context (persist session facts)
---

# Finish — End-of-Session Orchestrator

Wraps `/reflect` + `/save-context` in correct order. Call once at session end.

## Why Order Matters

`/reflect` needs **full conversation context** to find corrections, patterns, decisions. If `/save-context` runs first and compacts, that signal is lost. Always reflect first.

## Steps

1. **Invoke `/reflect`** — extract behavioral instincts while context is rich
2. **Invoke `/save-context`** — persist session facts (session-log, lessons-learned, memory)
3. **Report summary** — combine outputs from both

## Output

```
=== /finish ===

[/reflect output]
Extracted N instincts: ...

[/save-context output]
Session saved: ...

Session complete.
```

## When NOT to Use

- Mid-session checkpoint → use `/point` instead (lint, test, commit)
- Just want facts saved → use `/save-context` directly
- Just want instincts → use `/reflect` directly
