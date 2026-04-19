---
name: save-context
description: Use when context usage exceeds 80%, when user says "save context" or "save progress", or before ending a long session with significant decisions or code changes. Writes project-local state to `<cwd>/.context/` AND an extended session summary to `~/Documents/pr0j3cts/_vault/raw/sessions/` for cross-project memory.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
user-invocable: true
context: conversation
argument-hint: "[optional focus area]"
---

## Save Session Context

Immediately save all important information from the current session.

**Storage model (aligned with global CLAUDE.md):**
- `<cwd>/.context/` — **project-local** state: session-log, MEMORY, lessons-learned, todo, decisions. Committed to the project's git repo.
- `~/Documents/pr0j3cts/_vault/raw/sessions/` — **shared vault** extended session summary. Obsidian Git auto-commits + pushes.
- `~/.claude/projects/*/memory/` — **auto-memory system** (cross-project facts, managed by Claude Code itself). `save-context` does NOT write here.

All writes use `Write`/`Edit` directly — no MCP, no HTTP API, no ssh.

### Step 1: Ensure Project `.context/` Directory

Target: `<cwd>/.context/` (where `<cwd>` is the current working directory).

If `.context/` doesn't exist — create it:
- `mkdir -p <cwd>/.context`
- Create stub files if missing: `MEMORY.md`, `session-log.md`, `lessons-learned.md`, `todo.md`, `decisions.md` (each with a simple header)

### Step 2: Read Existing State

Read from `<cwd>/.context/`:
- `MEMORY.md` — project state
- `session-log.md` — chronological log
- `lessons-learned.md` — technical insights
- `todo.md` — pending items
- `decisions.md` — architectural decisions

### Step 3: Update session-log.md

If an entry for today's date exists — **update it** (don't duplicate).

Append/update entry with:
- Date + focus (what was worked on)
- What was discussed/done
- Decisions made
- Code changes (files, line ranges, commit hashes — use `git log --oneline -5`)
- Deployments + status
- Blockers + pending items
- **Review previous session's Pending** — mark completed, carry forward unresolved

~30-50 lines per session. Factual, not blow-by-blow.

### Step 4: Update lessons-learned.md

New technical insights only (bugs, gotchas, non-obvious solutions). Check for duplicates first.

**Scope:** technical knowledge. User preferences / behavioral feedback go via auto-memory (`~/.claude/rules/learned/*.md` or project memory dir) — not here.

### Step 5: Update MEMORY.md + todo.md + decisions.md

- **MEMORY.md** — refresh "Current Status" / state sections with latest facts
- **todo.md** — mark completed items `[x]`, add new pending `[ ]`
- **decisions.md** — append new architectural decisions with date + rationale (skip if none)

### Step 6: Write Extended Session Summary to Vault

Path: `~/Documents/pr0j3cts/_vault/raw/sessions/YYYY-MM-DD-HHMM-<project>.md`

- `YYYY-MM-DD-HHMM` = session start time. Never overwrite existing same-session files — keep earlier timestamp.
- `<project>` = cwd basename, lowercased, non-alphanumeric → `-`.
- PreCompact auto-snapshot at `...-<project>-auto.md` (if exists): leave it; this full summary supersedes.

**If vault path unavailable** (different Mac, missing folder): skip silently, note in Step 8 output.

**File format:**

```markdown
---
id: raw.session.YYYY-MM-DD-HHMM-<project>
type: raw
source: session
date: YYYY-MM-DD
project: <project>
summary: "<≤150 chars one-liner>"
---

# Session YYYY-MM-DD HH:MM — <project>

## TL;DR
<1-3 sentences>

## What Done
- <bullet>

## Decisions
- **<decision>** — <why / tradeoff>

## Insights
- <pattern / gotcha / non-obvious fact>

## Code Changes
- `path/to/file.ext` — <what / line range>
- Commits: `<sha> <message>`

## Blockers / Open Questions
- <item>

## Next
- <concrete next step>
```

Rules:
- Omit empty sections
- `summary` frontmatter = standalone one-liner (Graphify node label)
- Focus on **cross-project reusable knowledge**, not daily diary
- Don't re-narrate session-log contents

### Step 7: Git Commit `.context/` (if project is a git repo)

Per global rule "Session END: update ..., commit + push":

```bash
cd <cwd>
if git rev-parse --git-dir >/dev/null 2>&1; then
  git add .context/
  # only commit if .context/ has changes
  if ! git diff --cached --quiet .context/; then
    git commit -m "context: save session $(date +%Y-%m-%d)"
    # push only if upstream configured; otherwise report path
    git push 2>/dev/null || echo "push skipped (no upstream or permission)"
  fi
fi
```

If cwd is NOT a git repo → skip, note in output.

Do NOT commit/push anything outside `.context/` — no unrelated staging.

### Step 8: Confirm

Output format:

```
**Saved:**
- .context/session-log.md — <brief diff summary>
- .context/lessons-learned.md — <N new / no changes>
- .context/MEMORY.md — <updated / no changes>
- .context/todo.md — <N marked done / N added>
- .context/decisions.md — <N new / no changes>
- _vault/raw/sessions/<file>.md — <written / skipped (reason)>
- git: <committed <sha> / no changes / not a repo>
```

### Rules

- NEVER skip details. Every decision, file change, deploy status must land in session-log.
- If `$ARGUMENTS` given — focus the save on that area (e.g., "deployments").
- If nothing meaningful to save — say so, don't write empty updates.
- Check existing content before writing (avoid duplicates).
- Second invocation same day → **update** existing entry, don't duplicate.
- Vault write goes through `Write` only. Never use MCP `append_log`, `save_wiki`, or HTTP `/api/wiki/*` — those are legacy and will be removed (see task #36).
