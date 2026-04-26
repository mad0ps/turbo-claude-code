# Session Log — turbo-claude-code

## 2026-04-26 — /finish always-banner + statusline overflow fix + banner alignment

### Focus
Quality-of-life UX правки: `/finish` skill теперь всегда показывает "/clear next" баннер (не только при `clear` arg); кастомный statusline-command.sh адаптируется под длинные project names и узкий терминал. Фоллоу-ап: выровнял правую границу баннера (✅ занимает 2 cells, выпирала на 1 — убран один trailing space).

### Late update (after first /finish):
- **Banner alignment fix** (commit `0b5b521`): правый край рамки баннера в `/finish` был неровный из-за ✅ (2 visual cells по `unicodedata.east_asian_width="W"`), убран один trailing space в строке `║  ✅ Session saved.` → все 4 строки теперь = 42 visual cells. Push прошёл (`27f73ea..0b5b521`).

### Done

**`/finish` skill — always banner** (commit `ab672e3`):
- Удалён conditional `If $ARGUMENTS contains 'clear'`
- Frontmatter `argument-hint: "[clear]"` удалён, description обновлён
- Теперь после успешного reflect+save+wiki workflow всегда печатается `╔ ✅ Session saved → Run /clear ╗` блок
- Local effect мгновенный (через симлинк ~/.claude/skills/finish/ → repo)
- Push в github pending — Khan paste'ит `git push` сам

**Custom statusline-command.sh — overflow fix** (`~/.claude/statusline-command.sh`, не симлинк, локальный):
- Проблема: длинное project name (например `neurodivergent-screening-bot`) + полное `Opus 4.7 (1M context)` = line1 ≈ 84 chars + 5 эмодзи cells → wrap'ает на узком Claude Code statusline area → line2 (context bar + cost + duration) **скрывается** за allocated 2-line бюджет
- Fix 1: **model parenthetical compact** — regex `\((\S+)\s+context\)` → `(\1)`. `Opus 4.7 (1M context)` → `Opus 4.7 (1M)`, `Sonnet 4.5 (200K context)` → `Sonnet 4.5 (200K)`. Сэкономлено 8-10 cells.
- Fix 2: **adaptive truncate fallback** — terminal width детектится через `/dev/tty` + `termios.TIOCGWINSZ` ioctl (НЕ shutil.get_terminal_size — оно возвращает default 100 в subprocess без TTY); если total visible > term_cols, сначала truncate basename проекта с `…`, потом branch
- Test: `neurodivergent-screening-bot` сценарий — line1 79 chars (было 84), line2 71 chars — оба влезают в 80-cell terminal

**Discussion / decision** про невозможность chain'ить slash commands в Claude Code 2026:
- Khan хотел `/finish /clear` или новый `/fc` skill который сделает оба
- Проверено через claude-code-guide subagent: hooks не могут invoke slash commands, keybindings supports только submit/cancel/clearInput (не macro), `claude -p "/finish clear" && claude` shell alias не работает (non-interactive `-p` без state текущей сессии)
- Решение: всегда печатать баннер после `/finish` + принять two-step UX

### Decisions
- **Always banner после `/finish`** — no flag, single behavior. UX consistency.
- **Statusline tells terminal size через /dev/tty ioctl** — единственный надёжный путь для subprocess без TTY на stdin.
- **Statusline остаётся локальным файлом, не симлинк в репу** — изменение работает мгновенно, для propagation на сервер позже можно перенести.
- **Принять two-step `/finish` → `/clear`** — нет смысла бороться с design constraint Claude Code.

### Code Changes
- `skills/finish/SKILL.md` — frontmatter cleanup + always-print banner section (commit `ab672e3`, 4 ins / 7 del)
- `~/.claude/statusline-command.sh` (local, not in repo) — model `(1M context)` strip + ioctl-based term_cols + adaptive truncate

### Memory
- 1 instinct extracted в `~/.claude/rules/learned/tools.md`: невозможность chain'ить slash commands (decision, 0.8), плюс statusline ioctl pattern (correction, 0.7) добавлен в этой же сессии ранее

### Next session
- Если статусbar где-то ещё ломается — проверить term_cols detection (на macOS Terminal.app vs iTerm2 vs WezTerm — TIOCGWINSZ должен работать одинаково, но возможны edge cases)
- Возможно перенести statusline-command.sh в `turbo-claude-code/scripts/` + симлинк, если хочется git-tracking
