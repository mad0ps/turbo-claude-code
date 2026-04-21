---
name: wiki-lint
description: Use when the vault quality needs an audit — find broken [[wikilinks]], orphan nodes, stale pages (>60d), missing frontmatter fields, empty ## hot sections. Produces a dated report in raw/inbox/, never auto-fixes.
---

# /wiki-lint — vault quality audit

## Overview

Read-only quality scan for `~/Documents/pr0j3cts/_vault/wiki/`. Detects drift that accumulates between curate runs and makes `graphify query` stale or confusing.

**No auto-fix.** Khan decides what to fix. Output is a dated report in `raw/inbox/wiki-lint-YYYY-MM-DD.md`.

## Usage

```
/wiki-lint                # full audit, writes report
/wiki-lint --dry-run      # print summary, don't write report
/wiki-lint --stale-days N # override 60-day threshold
```

## What to do when invoked

### Step 1 — cd into vault, pre-flight

```bash
cd ~/Documents/pr0j3cts/_vault
test -f graphify-out/graph.json || echo "WARN: graph.json missing — run \`graphify update .\` first, orphan check will be skipped"
```

### Step 2 — run the 5 checks (Python one-shot)

Use this script. It emits JSON to stdout — parse + render the report from it. Do **not** rewrite each check as separate Bash invocations (slow + fragile).

```bash
python3 - <<'PY'
import json, re, sys, datetime, os
from pathlib import Path
from collections import Counter

VAULT = Path('.').resolve()
WIKI = VAULT / 'wiki'
STALE_DAYS = int(os.environ.get('WIKI_LINT_STALE_DAYS', '60'))
TODAY = datetime.date.today()

required_fields = ('id', 'type', 'updated')

def parse_frontmatter(txt):
    m = re.match(r'^---\n(.*?)\n---\n', txt, re.DOTALL)
    if not m:
        return None, txt
    fm = {}
    for line in m.group(1).splitlines():
        mm = re.match(r'^(\w+):\s*(.*)$', line)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip().strip('"\'')
    return fm, txt[m.end():]

pages = sorted(WIKI.rglob('*.md'))
page_ids = {}
for p in pages:
    fm, _ = parse_frontmatter(p.read_text())
    if fm and fm.get('id'):
        page_ids[fm['id']] = p
    # also index by filename stem for wikilink resolution
    page_ids.setdefault(p.stem, p)

broken_links, missing_fm, stale, empty_hot, orphans = [], [], [], [], []

for p in pages:
    rel = p.relative_to(VAULT)
    txt = p.read_text()
    fm, body = parse_frontmatter(txt)

    # 1) missing frontmatter fields
    if fm is None:
        missing_fm.append((str(rel), '(no frontmatter block)'))
    else:
        missing = [f for f in required_fields if not fm.get(f)]
        if missing:
            missing_fm.append((str(rel), f"missing: {', '.join(missing)}"))

    # 2) stale
    if fm and fm.get('updated'):
        try:
            u = datetime.date.fromisoformat(fm['updated'])
            age = (TODAY - u).days
            if age > STALE_DAYS:
                stale.append((str(rel), f"updated {age}d ago ({fm['updated']})"))
        except Exception:
            pass

    # 3) empty ## hot
    hot_m = re.search(r'^##\s+hot\s*$(.*?)(?=^##\s|\Z)', body, re.MULTILINE | re.DOTALL)
    if hot_m:
        content = re.sub(r'<!--.*?-->', '', hot_m.group(1), flags=re.DOTALL).strip()
        if not content:
            empty_hot.append(str(rel))

    # 4) broken wikilinks
    for link in re.findall(r'\[\[([^\]\|#]+)(?:\|[^\]]*)?\]\]', body):
        target = link.strip()
        if target in page_ids:
            continue
        # also try lowercased / dot-variant
        if target.lower() in (k.lower() for k in page_ids):
            continue
        broken_links.append((str(rel), target))

# 5) orphans from graph.json
gpath = VAULT / 'graphify-out' / 'graph.json'
if gpath.exists():
    g = json.loads(gpath.read_text())
    deg = Counter()
    for l in g['links']:
        deg[l['source']] += 1
        deg[l['target']] += 1
    for n in g['nodes']:
        if deg[n['id']] == 0 and 'wiki/' in (n.get('source_file') or ''):
            orphans.append((n['id'], n['source_file']))

result = {
    'scanned_pages': len(pages),
    'stale_days_threshold': STALE_DAYS,
    'broken_links': broken_links,
    'missing_fm': missing_fm,
    'stale': stale,
    'empty_hot': empty_hot,
    'orphans': orphans,
}
print(json.dumps(result, ensure_ascii=False, indent=2))
PY
```

Capture stdout, parse as JSON.

### Step 3 — render report

Build `raw/inbox/wiki-lint-YYYY-MM-DD.md`:

```markdown
---
id: raw.inbox.wiki-lint-YYYY-MM-DD
type: raw
source: lint
date: YYYY-MM-DD
summary: "wiki-lint: <N broken links, M orphans, K stale, P missing frontmatter, Q empty hot>"
---

# wiki-lint — YYYY-MM-DD

Scanned: **<N> pages** in `wiki/`. Stale threshold: **<days>d**.

## Broken wikilinks (<count>)

Pages referencing `[[target]]` that doesn't resolve to any wiki page.

- `<file>` → `[[<target>]]`
- ...

## Orphan nodes (<count>)

Wiki pages that have zero edges in the knowledge graph — nobody links to them, they link to nobody. Candidates for merge or delete.

- `<id>` — `<file>`
- ...

## Stale pages (<count>, >Xd)

- `<file>` — <age description>
- ...

## Missing frontmatter (<count>)

Required: `id`, `title`, `type`, `updated`.

- `<file>` — <missing fields>
- ...

## Empty ## hot (<count>)

Page has `## hot` header but no content below.

- `<file>`
- ...

---

## Next actions (for Khan, not auto)

- Broken links: run `/curate` on adjacent raw/ material, or delete dangling links
- Orphans: merge into sibling page, or delete, or add related[] cross-links
- Stale: audit — is it still true? rewrite ## hot, bump updated:
- Missing FM: backfill using stub template from /curate skill
- Empty hot: run `/curate` on the page's raw/ fragments
```

Skip sections with 0 findings (just omit the heading).

**If `--dry-run`:** print the summary counts to stdout instead of writing the file.

### Step 4 — summary to user

Print one-liner: `wiki-lint → raw/inbox/wiki-lint-YYYY-MM-DD.md : B broken, O orphans, S stale, F missing FM, H empty hot`.

Never commit the report. Khan decides.

## Boundaries

- **Read-only.** Never mutate wiki/. Never auto-fix.
- **Never commit or push.** Khan reviews findings.
- **Don't flag `## hot` as empty** on category hubs that intentionally have no hot section (check for `type: hub` in frontmatter — skip those for the empty-hot check if you add that exception later).
- **Don't flag raw/** — lint is wiki-quality only. raw/ is append-only and mostly doesn't have frontmatter discipline.

## Red flags — STOP

- About to `git rm` a wiki page flagged as orphan → no, write the name to report, let Khan decide
- About to rewrite `## hot` of a stale page → no, that's /curate's job, not /wiki-lint's
- Running auto-fix based on lint output → no. Lint is diagnostics only.

ARGUMENTS: ALL
