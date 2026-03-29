# Global Rules

## Golden Rule
**ВРЕМЯ = САМЫЙ ЦЕННЫЙ РЕСУРС.** Не гадать — сразу лезть на сервер/в среду и разбираться. Не пушить наугад, тестировать на месте. Каждый холостой deploy-цикл — потерянное время.

## Language
All communication in Russian unless user switches to English.

## Commands

### "." (точка сохранения)
Invoke `/point` skill — atomic checkpoint: lint → test → log → commit → push → verify CI.

### "claude sync"
Synchronize project CLAUDE.md with docs/ folder. CLAUDE.md = source of truth, docs/ = detailed docs.

## Server Access
- SSH к серверам разрешён для проверки логов и диагностики
- НИКОГДА не запускать build, deploy, restart или любые деструктивные команды на серверах напрямую
- ВСЕ деплои идут через CI/CD (push → GitHub Actions → deploy)
- Если нужен фикс на сервере — коммит + пуш, CI/CD сделает остальное
- Конкретные серверы — в project CLAUDE.md каждого проекта

## Conventions
- Use TodoWrite to track multi-step tasks
- Mark todos as completed immediately after finishing each one
- Commit messages in English, concise, descriptive
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
