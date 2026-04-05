# Domain Knowledge (lazy-load)

Files here are NOT loaded automatically. Claude reads them on demand when entering a relevant domain.

## How it works
- `rules/learned/` → always loaded (universal instincts)
- `knowledge/` → loaded when domain is detected (saves tokens)

## Adding new domains
Create `{domain}.md` with `# {Domain} Knowledge` header and `## Instincts` section.
Examples: `devops.md`, `marketing.md`, `security.md`, `data-engineering.md`

## Format
```
0.8 | trigger condition → action to take (source, date)
```
