# Decisions — turbo-claude-code

## 2026-04-26 — `/finish` всегда печатает баннер про /clear (no flag)
Конкатенация `Session complete.` + `╔ Run /clear ╗` блок печатается в каждом прогоне `/finish`, без условного `clear` аргумента. Frontmatter `argument-hint` удалён.

**Why:** Khan хочет one-action UX. Chain'ить `/finish` → `/clear` нельзя (Claude Code 2026 не поддерживает skill-from-skill вызов runtime-команд, hooks тоже не могут). Постоянный prominent баннер делает two-step workflow вычислимым: всегда жмёшь `/clear` после `/finish` без раздумий.

## 2026-04-26 — Statusline detects terminal cols через /dev/tty ioctl, не shutil
`statusline-command.sh` запускается Claude Code как subprocess с stdin = JSON pipe. `shutil.get_terminal_size()` возвращает default 100 в этом контексте, что не отражает actual TUI width. Fix: открыть `/dev/tty` и сделать `fcntl.ioctl(f, termios.TIOCGWINSZ)` — это даёт **реальную** ширину окна.

**Why:** Khan столкнулся с overflow line1 на длинных project names (`neurodivergent-screening-bot`) — line2 (context bar/cost) исчезала. Требовалась честная адаптация под ширину.

## 2026-04-26 — Compact model parenthetical: `(1M context)` → `(1M)`
Regex `\((\S+)\s+context\)` → `(\1)`. Применяется к model.display_name перед рендером.

**Why:** Полное `(1M context)` дублирует информацию (читателю ясно что 1M = context window) и ест 8 cells. Strip оставляет суть, сохраняя differentiation между 200K/1M режимами.
