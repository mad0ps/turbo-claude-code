# TODO — turbo-claude-code

## Pending
- [ ] Опционально: перенести `~/.claude/statusline-command.sh` в `scripts/statusline-command.sh` + симлинк, чтобы git-track и propagate на сервер
- [ ] Refactor `hooks/danger-blocker.sh` regex item 1 (`rm -rf /`) — anchor на actual command start чтобы не ловить text в heredoc / commit message
- [ ] Если term_cols detection через /dev/tty покажет проблемы на каких-то терминалах (WezTerm, Alacritty, Tmux) — добавить fallback chain

## Done
- [x] **2026-04-26** /finish skill: always-banner (commit ab672e3) — drop conditional `clear` arg
- [x] **2026-04-26** statusline-command.sh: model parens compact (`(1M context)`→`(1M)`) + adaptive truncate basename via /dev/tty ioctl
