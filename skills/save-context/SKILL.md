---
name: save-context
description: Use when context usage exceeds 70%, when user says "save context" or "save progress", or before ending a long session with significant decisions or code changes.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
user-invocable: true
context: conversation
argument-hint: "[optional focus area]"
---

## Save Session Context

Immediately save all important information from the current session to memory files.

### Step 1: Detect Project Memory Directory

Find the current project's memory directory:
- Use Glob to find memory files: `$HOME/.claude/projects/*/memory/MEMORY.md`
- Match based on the current working directory (the project path is encoded in the directory name with `-` replacing `/`)
- If no memory directory exists — **create it**: `mkdir -p $HOME/.claude/projects/<encoded-path>/memory` and create `MEMORY.md`, `session-log.md`, `lessons-learned.md` with headers

### Step 2: Read Current Memory Files

Read from the detected project memory directory:
- `MEMORY.md` — main memory file
- `session-log.md` — chronological session log (if exists)
- `lessons-learned.md` — insights and mistakes (if exists)

If any file doesn't exist, create it with an appropriate header.

### Step 3: Update session-log.md

Check if an entry for today's date already exists. If yes — **update it** (don't create a duplicate).

Append (or update) a session entry with:
- Date and context (what project, what was the focus)
- What was discussed this session
- Decisions made
- Code changes (files, what changed, commit hashes if available — use `git log --oneline -5` to check)
- Deployments and their status
- Blockers and pending items
- **Review previous session's "Pending" section** — mark completed items, carry forward unresolved ones

Keep entries factual and concise — record WHAT and WHY, not blow-by-blow narratives. Aim for ~30-50 lines per session.

### Step 4: Update lessons-learned.md

If new **technical** insights were discovered during the session (bugs, gotchas, non-obvious solutions), append them. Check existing entries first to avoid duplicates.

**Note:** lessons-learned.md is for technical knowledge (e.g., "Telegram postbox/db is NOT cache"). User preferences and behavioral feedback should be saved as separate memory files using the auto-memory system (type: `user` or `feedback`) if the project's CLAUDE.md defines one.

### Step 5: Update MEMORY.md

Update the "Current Status" section (or equivalent) with latest state. If new significant information was learned about the project, servers, tools, or user — update the relevant sections.

### Step 6: Confirm

Report what was saved in this format:

**Saved to [directory]:**
- **session-log.md** — [brief summary of what was added]
- **lessons-learned.md** — [N new lessons / no changes]
- **MEMORY.md** — [what was updated / no changes]

### Rules

- NEVER skip details. Every decision, file change, deployment status must be recorded. Details omitted from session logs are effectively lost between sessions — record everything.
- If $ARGUMENTS is provided, focus the save on that specific area (e.g., "deployments", "decisions", "code changes")
- If there's nothing meaningful to save, say so instead of writing empty updates
- Check for existing content before writing to avoid duplicating information
- If today's session entry already exists (skill called twice) — update it, don't create a second one
- When updating Pending sections, mark previously pending items that were completed this session
