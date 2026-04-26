# Memory — turbo-claude-code

## What is this
Custom skills, hooks, rules, knowledge для Claude Code. Source of truth — github.com/mad0ps/turbo-claude-code. ~/.claude/ работает через симлинки на этот репозиторий.

## Layout
```
hooks/          ← bash hooks (PreToolUse danger-blocker, SessionStart injector, etc) — симлинки в ~/.claude/hooks/
skills/         ← кастомные skills (lazy-load) — симлинки в ~/.claude/skills/
rules/learned/  ← always-loaded behavior rules (workflow.md, tools.md ~85 lines total)
knowledge/      ← lazy-load domain (design, devops, security, etc)
install.sh      ← idempotent setup для нового Mac/server
```

## Active hooks (registered in ~/.claude/settings.json)
- PreToolUse:Bash — `danger-blocker.sh` (rm -rf, DROP, git push --force, systemctl stop/restart, ssh sudo systemctl/reboot, docker system prune)
- PostToolUse:Bash — `filter-bash-output.sh`
- SessionStart — `plugin-update-check.sh` + `session-start-injector.sh`
- Stop — `stop-reminder.sh`
- PreCompact — `pre-compact-snapshot.sh`
- PreToolUse:Read — `vault-query-gate.sh` (форсит graphify query на _vault/{raw,wiki})
- PostToolUse:Edit/Write — `vault-graph-stale.sh` (помечает graph stale при wiki write)

## Skills (in repo)
- `/curate` — raw → wiki orchestrator
- `/wiki-lint` — vault quality scan
- `/ask-vault` — graphify query wrapper
- `/finish` — reflect + save-context + wiki append + (always) /clear banner
- `/save-context`, `/reflect`, `/point` — primary atomic skills
- (others) `/go`, `/learn`, `/fact-check`, `/deploy-check`, `/web-research`

## Local-only files (not in repo, propagation via copy)
- `~/.claude/statusline-command.sh` — Python statusline rendering (model parens compact + adaptive truncate via /dev/tty ioctl, fixed 2026-04-26)
- `~/.claude/CLAUDE.md` — global rules (Russian, golden rule about time, server access policies)
- `~/.claude/settings.json` — hook registration, env vars (CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=95)

## Conventions
- Skills/rules написаны на английском (token efficiency)
- Симлинки = source of truth. НЕ редактировать ~/.claude/* напрямую если симлинк (только если local-only file)
- `[clear]` argument-hint в /finish удалён — banner теперь always
- После добавления хука — зарегистрировать в settings.json
