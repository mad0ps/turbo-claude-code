---
name: finish
description: Use when user invokes /finish or ends a session — orchestrates /reflect, /save-context, and vault wiki-append. Always ends with a prominent prompt to run /clear (skills can't invoke /clear directly).
---

# Finish — End-of-Session Orchestrator

Wraps `/reflect` + `/save-context` + vault wiki-append in correct order. Call once at session end.

## Storage Alignment (post-#33 git-only flow)

- `<cwd>/.context/` — project-local state (written by `/save-context`)
- `~/Documents/pr0j3cts/_vault/raw/sessions/*.md` — session summary (written by `/save-context`)
- `~/Documents/pr0j3cts/_vault/wiki/projects/project.<name>.md` — long-lived project note (updated by THIS skill, step 3)
- `~/.claude/rules/learned/*.md` — behavioral instincts (written by `/reflect`)

All writes go through `Write`/`Edit` directly. **No MCP, no HTTP API, no ssh.** Obsidian Git plugin picks up vault changes within 10 min and pushes to GitHub.

## Why Order Matters

`/reflect` needs **full conversation context** to find corrections, patterns, decisions. If `/save-context` runs first and compacts, that signal is lost. Always reflect first.

## Steps

1. **Invoke `/reflect`** — extract behavioral instincts while context is rich
2. **Invoke `/save-context`** — persist session facts (project `.context/`, vault `raw/sessions/`)
3. **Vault wiki-append** — update the project's wiki note in `_vault/wiki/projects/`:
   - Derive note_id: `project.<cwd-basename>` (e.g., cwd `memory-mcp` → `project.memory-mcp`)
   - Target file: `~/Documents/pr0j3cts/_vault/wiki/projects/<note_id>.md`
   - If file exists:
     - Use `Edit` to prepend one line to the `## log` section: `- YYYY-MM-DD — <what was done, decisions, deploys — one line, no fluff>`
     - If `## hot` section needs a state change (new milestone, blocker, pivot) — update it too via `Edit`
     - Bump `updated: 'YYYY-MM-DD'` in frontmatter
   - If file doesn't exist → skip (not every cwd has a wiki note; that's fine)
   - **Never** use MCP `append_log`, `save_wiki`, or HTTP `/api/wiki/*` — legacy, being removed in task #36
4. **Report summary** — combine outputs from all steps
5. **Always append the prominent /clear prompt** — Claude Code can't auto-invoke `/clear` from a skill (it's a runtime command), so the user runs it manually as the second action. Showing the banner every time keeps the workflow consistent: `/finish` always means "save + ready for /clear".

## Output

Always prints both blocks back-to-back:

```
=== /finish ===

Reflect: N instincts extracted
Save-context: .context/ updated + vault/raw/sessions/<file>.md written
Vault: project.memory-mcp — log +1 line, updated=YYYY-MM-DD
  (or: project.<name>.md not found, skipped)

Session complete.

╔════════════════════════════════════════╗
║  ✅ Session saved.                     ║
║  → Run /clear now for fresh context    ║
╚════════════════════════════════════════╝
```

## When NOT to Use

- Mid-session checkpoint → use `/point` instead (lint, test, commit)
- Just want facts saved → use `/save-context` directly
- Just want instincts → use `/reflect` directly
