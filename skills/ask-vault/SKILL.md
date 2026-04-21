---
name: ask-vault
description: Use when answering any question about vault content (who Khan is, past decisions, project history, tools, people, patterns stored in ~/Documents/pr0j3cts/_vault). Wraps graphify query + synthesis so Claude never re-reads raw/ or wiki/ directly.
---

# /ask-vault — query the knowledge graph, synthesize

## Overview

Librarian-mode retrieval for `~/Documents/pr0j3cts/_vault`. Avoids the trap of `Read raw/*.md` or `Grep wiki/` — those are the exact waste graphify was built to prevent.

Flow: `graphify query` → if on-target, synthesize 3-5 bullets with sources → else narrow with `path`/`explain`/focused query → only if still empty, escape with `VAULT_DIRECT_READ=1` for targeted Read.

## Usage

```
/ask-vault <question>
```

Examples:
- `/ask-vault кто я?`
- `/ask-vault что мы решили про vault-backup.sh?`
- `/ask-vault как устроен voidroute MVP?`
- `/ask-vault связь между AuDHD и hyperfocus в заметках`

## What to do when invoked

### Step 1 — cd into vault

```bash
cd ~/Documents/pr0j3cts/_vault
```

All graphify commands need to run from vault root so `graphify-out/graph.json` is found.

### Step 2 — primary query (BFS, budget-capped)

```bash
graphify query "$ARGS"
```

Defaults: BFS traversal, 2000-token budget. Shows matched nodes + their neighborhood + confidence-tagged edges.

**Read the output.** If it has 3+ relevant nodes for Khan's question — skip to Step 5 (synthesize).

### Step 3 — if sparse, widen

If query returned <3 relevant nodes OR looks off-topic:

```bash
graphify query "$ARGS" --budget 4000
```

If still sparse, try DFS (depth over breadth — follows one thread):

```bash
graphify query "$ARGS" --dfs --budget 3000
```

If user's question names two concepts (A and B), check direct path:

```bash
graphify path "A" "B"
```

If user asks about one specific entity, get its neighborhood:

```bash
graphify explain "<NodeName>"
```

### Step 4 — fallback (rare)

Only if graphify returned nothing useful:

```bash
# Check if the graph even covers the topic
Read graphify-out/GRAPH_REPORT.md  # god nodes + communities overview

# If still empty and user's question clearly points at specific file:
VAULT_DIRECT_READ=1 Read _vault/wiki/<path>.md
```

Tell the user: "graphify query returned nothing — falling back to direct read, graph may need re-curate."

### Step 5 — synthesize

Produce **3-5 bullets**, each tied to a source. Keep under 2K tokens.

Format:
```
<3-5 bullets answering the question, concrete + short>

Sources:
- <wiki-path or raw-path>  — <why it's the source>
- <node-id from graphify>  — <what it contributed>
```

Rules:
- **Never** paste raw file contents. Compress.
- **Never** invent facts. If graphify returned it — cite it. If not — say "not in vault".
- **Always** show what you ran (`graphify query "..."`) so Khan can re-run.
- If confidence on key edges was AMBIGUOUS/INFERRED — flag it.

## Boundaries

- Don't write to vault. This skill is read-only.
- Don't commit. Khan commits.
- Don't re-run graphify update. That's a separate command; this skill reads, doesn't refresh.
- Don't Read raw/wiki files directly unless Step 4 escape triggered — the `vault-query-gate.sh` hook will block you anyway.

## Red flags — STOP

- About to `cat` or `Read` a raw/wiki file before running `graphify query` → wrong order, start with query
- Pasting full raw content into the answer → over-retrieval, compress
- Guessing when graphify returned nothing → say "not found", don't fabricate

ARGUMENTS: ALL
