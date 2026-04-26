# Lessons Learned — turbo-claude-code

## 2026-04-26

**Claude Code statusline runs as subprocess without TTY on stdin**
`statusLine.command` запускается с stdin = JSON pipe. `shutil.get_terminal_size()` в таком контексте возвращает (100, 24) default — не отражает actual TUI width. Workaround: открыть `/dev/tty` (это controlling terminal текущего process tree) и сделать `fcntl.ioctl(fd, termios.TIOCGWINSZ, b'\\0'*8)` → получить настоящие cols/rows. Работает на macOS (Terminal.app, iTerm2). На headless серверах (без TTY) fail'ает с `OSError: not a tty` — fallback на `os.environ['COLUMNS']`, потом fixed 100.

**Slash commands не chain'аются в Claude Code 2026**
Verified через claude-code-guide subagent + own testing:
- `/finish /clear` парсится как `/finish $ARGUMENTS="/clear"` — второй slash идёт текстом
- Hooks возвращают JSON decision, нет API чтобы триггернуть command
- Keybindings поддерживают `chat:submit`, `chat:cancel`, `chat:clearInput` — без macro/sequence
- `claude -p "/finish clear"` non-interactive subprocess без state текущей сессии (нельзя save актуальный context)
- OS-level workaround: Karabiner / iTerm2 keymapping → отправить два input'а с задержкой

**Model display_name содержит parenthetical suffix только если режим не default**
Sample observed: `Opus 4.7 (1M context)`, `Sonnet 4.5 (200K context)`, `Haiku 4.5` (no suffix), `Opus 4.7 (thinking)`. Regex `\((\S+)\s+context\)` ловит первую группу (1M/200K) и compact'ит до `(1M)`. Не трогает `(thinking)` и другие неcontext-обоснования.

**`~/.claude/statusline-command.sh` — local-only, не симлинк**
В отличие от skills/hooks, statusline-command.sh лежит напрямую в `~/.claude/`, не через симлинк на repo. Изменения работают мгновенно но не propagate на сервер автоматически. Для дистрибьюции — переносить в `turbo-claude-code/scripts/` + симлинк (или manual copy).
