# Global Rules

## Golden Rule
**ВРЕМЯ = САМЫЙ ЦЕННЫЙ РЕСУРС.** Не гадать — сразу лезть на сервер/в среду и разбираться. Не пушить наугад, тестировать на месте. Каждый холостой deploy-цикл — потерянное время.

## Language
All communication in Russian unless user switches to English.

## Commands
- `"."` → invoke `/point` skill (atomic checkpoint: lint → test → log → commit → push → verify CI)
- `"claude sync"` → synchronize project CLAUDE.md with docs/ folder (CLAUDE.md = source of truth)

## Server Access
- SSH разрешён для логов и диагностики, НИКОГДА не запускать build/deploy/restart напрямую
- ВСЕ деплои через CI/CD (push → GitHub Actions → deploy)
- Конкретные серверы — в project CLAUDE.md каждого проекта

## Project Memory (.context/)
All session context MUST live inside the project directory in `.context/`. This ensures portability.
Required files: `MEMORY.md`, `session-log.md`, `lessons-learned.md`, `todo.md`, `decisions.md`
- Session START: read `.context/MEMORY.md` + last entry in `session-log.md` + `todo.md`
- Session END: update `session-log.md`, `todo.md`, `MEMORY.md`. Commit + push
- `.context/` MUST be committed to git (not in .gitignore)
- Note: `~/.claude/projects/*/memory/` is used by auto-memory system (cross-project facts), `.context/` is for project-specific state

## NeuroCortex — Partner Memory System
At session START: read `~/Documents/pr0j3cts/neuro-cortex/CORTEX.md` + `handoff.md`
Deep-dive files (khan.md, patterns.md, capabilities.md) — read when relevant, not every time.

## Conventions
- Use TodoWrite to track multi-step tasks, mark completed immediately
- Commit messages in English, concise, descriptive
- No Co-Authored-By in commits
