# Everything Claude Code (affaan-m/everything-claude-code)

> **TL;DR:** Репозиторий-победитель Anthropic Hackathon (111k+ stars) — комплексная система оптимизации Claude Code: 125+ skills, 28 subagents, 60+ slash commands, hooks, security scanning. Не просто конфиг, а production-ready фреймворк для "harness performance optimization". Ключевая ценность — готовые паттерны для memory persistence, token optimization, параллельной работы и continuous learning.

## Key Concepts

| Concept | What It Is | Why It Matters |
|---------|-----------|----------------|
| **Skills** | Workflow-определения в `~/.claude/skills/` | Переиспользуемые паттерны работы, не нужно каждый раз объяснять Claude одно и то же |
| **Commands** | Slash-команды в `~/.claude/commands/` | Быстрый запуск повторяющихся workflows одной командой (/tdd, /e2e, /plan) |
| **Hooks** | Триггеры на lifecycle events (PreToolUse, PostToolUse, Stop, PreCompact) | Автоматизация: авто-форматирование, memory persistence, security checks |
| **Subagents** | Делегированные процессы с ограниченным scope | Экономия контекста главного агента, параллелизация, специализация |
| **MCPs** | Model Context Protocol — подключение внешних сервисов | Прямой доступ к GitHub, Supabase, БД без копипаста |
| **Rules** | Модульные `.md` правила в `~/.claude/rules/` | Структурированные инструкции вместо одного гигантского CLAUDE.md |
| **AgentShield** | Security-сканер для конфигов Claude | Находит секреты, инъекции в hooks, рискованные MCP, уязвимости agents |
| **Continuous Learning** | Авто-извлечение паттернов из сессий в skills | Claude учится на своём опыте, не повторяет ошибки |

## Patterns & Best Practices

### Pattern 1: Token Optimization — Model Selection Matrix
- **When:** Выбор модели для задачи
- **How:** Sonnet для 90% кодинга. Opus — если первая попытка провалилась, 5+ файлов, архитектура, security. Haiku — поиск, документация, простые правки
- **Example:**
  ```
  Exploration/search → Haiku (быстро, дёшево)
  Multi-file coding  → Sonnet (баланс)
  Architecture       → Opus (глубокий reasoning)
  Security analysis  → Opus (нельзя пропустить)
  Documentation      → Haiku (простая структура)
  ```

### Pattern 2: MCP Replacement Strategy
- **When:** Используешь тяжёлые MCPs (GitHub, Supabase, Vercel) постоянно
- **How:** Заменить на CLI-based skills и commands. Каждый MCP жрёт токены из 200k окна — с 20+ MCPs может остаться 70k
- **Example:** Вместо GitHub MCP → создать `/gh-pr` команду обёртку над `gh pr create`

### Pattern 3: Session Memory Persistence
- **When:** Работа на несколько дней, нужно не терять контекст между сессиями
- **How:** Stop Hook сохраняет state в файл, SessionStart Hook загружает. Включить: verified approaches, failed approaches, remaining tasks
- **Example:**
  ```bash
  # Stop Hook: сохраняет прогресс
  # SessionStart Hook: загружает контекст предыдущей сессии
  # Или ручной подход:
  alias claude-dev='claude --system-prompt "$(cat ~/.claude/contexts/dev.md)"'
  ```

### Pattern 4: Parallel Workflows через Git Worktrees
- **When:** 2+ независимых задачи одновременно
- **How:** Git worktrees + отдельный Claude instance в каждом. Max 3-4 concurrent tasks. Cascade method: новые задачи в табах справа, sweep слева направо
- **Example:**
  ```bash
  git worktree add ../project-feature-a feature-a
  git worktree add ../project-feature-b feature-b
  cd ../project-feature-a && claude
  ```

### Pattern 5: Two-Instance Project Kickoff
- **When:** Старт нового проекта
- **How:** Instance 1 — scaffolding (структура, CLAUDE.md, rules). Instance 2 — deep research (внешние сервисы, PRD, архитектура, Mermaid-диаграммы)
- **Example:** Запустить параллельно, затем объединить результаты

### Pattern 6: Sequential Phase Architecture для Subagents
- **When:** Сложная задача требующая нескольких специалистов
- **How:** RESEARCH → PLAN → IMPLEMENT → REVIEW → VERIFY. Каждый агент: один вход, один выход. Выход = вход следующей фазы
- **Example:**
  ```
  Phase 1: Explore agent → research-summary.md
  Phase 2: Planner agent → plan.md
  Phase 3: TDD-guide agent → code changes
  Phase 4: Code-reviewer agent → review-comments.md
  Phase 5: Build-error-resolver → done or retry
  ```

### Pattern 7: Continuous Learning через Stop Hook
- **When:** Хочешь чтобы Claude учился на каждой сессии
- **How:** Stop Hook (не UserPromptSubmit — тот добавляет latency на каждое сообщение) извлекает паттерны и сохраняет как skills
- **Example:** Debugging technique → skill, workaround → skill, project pattern → skill

### Pattern 8: Context Window Management
- **When:** Всегда. Context = самый ценный ресурс
- **How:** Max 10 MCP активных / 80 tools. Отключить auto-compact, делать manual compact на логических границах. Файлы < 1000 строк. `mgrep` вместо grep (~50% token reduction)
- **Example:**
  ```bash
  /mcp          # проверить активные MCPs
  /plugins      # проверить активные плагины
  /compact      # ручной compact
  ```

## Quick Reference

| Task | How |
|------|-----|
| Установить как plugin | `/plugin install everything-claude-code@everything-claude-code` |
| Установить rules вручную (macOS) | `bash install.sh` из корня репо |
| Установить selective (npm) | `npx ecc-install typescript` (или python, go, java...) |
| Проверить context usage | `/mcp` и `/plugins` — отключить неиспользуемые |
| Заменить MCP на CLI | Создать skill/command обёртку над CLI инструментом |
| Создать hook conversationally | Плагин `hookify@claude-plugins-official` |
| Security scan | `/security-scan` или `--opus` для red-team анализа |
| Session memory | Stop Hook + SessionStart Hook для persistence |
| Parallel work | `git worktree add ../branch-name branch-name && cd ../branch-name && claude` |
| Найти llms-friendly docs | Добавить `/llms.txt` к URL документации |
| Быстрый bash | `!` перед командой |
| Поиск файлов | `@` для file search |
| Multi-line input | `Shift+Enter` |
| Форк беседы | `/fork` |
| Откат | `/rewind` |
| Custom status line | `/statusline` |

## Common Mistakes

| Mistake | Why It's Wrong | Do This Instead |
|---------|---------------|-----------------|
| Включить все 20+ MCPs сразу | Context window падает с 200k до ~70k | Max 10 MCPs активных, остальные disabled |
| Один гигантский CLAUDE.md | Сложно поддерживать, Claude теряет фокус | Модульные rules в `~/.claude/rules/`: security.md, testing.md, etc. |
| Auto-compact по умолчанию | Теряется контекст в неподходящий момент | Disable auto-compact, manual `/compact` на логических границах |
| Goroutine/thread на каждое соединение к субагенту | Взрывной рост memory | Bounded worker pool pattern |
| Повторять одни и те же промпты | Трата токенов и контекста | Конвертировать в skills/commands |
| UserPromptSubmit для memory | Latency на каждое сообщение | Stop Hook — один раз в конце сессии |
| Параллелить всё подряд (10 terminals) | Overlap и конфликты | Max 3-4 concurrent, git worktrees, cascade method |
| Полагаться только на training data | Может быть устаревшим | Всегда web search для актуальной инфо |
| Не передавать контекст субагентам | Субагент не знает PURPOSE, только query | Передавать objective context, не просто вопрос |

## Resources

- [GitHub: affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — сам репозиторий (111k+ stars, MIT)
- [The Longform Guide](https://github.com/affaan-m/everything-claude-code/blob/main/the-longform-guide.md) — детальный гайд: token optimization, memory, evals, parallelization
- [The Shortform Guide](https://github.com/affaan-m/everything-claude-code/blob/main/the-shortform-guide.md) — быстрый старт: skills, hooks, MCPs, setup
- [The Security Guide](https://github.com/affaan-m/everything-claude-code/blob/main/the-security-guide.md) — AgentShield, attack vectors, sandboxing
- [Medium: Repo That Won Anthropic Hackathon](https://medium.com/@joe.njenga/everything-claude-code-the-repo-that-won-anthropic-hackathon-33b040ba62f3) — разбор победы на хакатоне
- [Anthropic Best Practices](https://code.claude.com/docs/en/best-practices) — официальные рекомендации Anthropic
- [ykdojo/claude-code-tips](https://github.com/ykdojo/claude-code-tips) — 45 tips (дополнительный ресурс)
- [Claude Code Tips & Tricks (Medium)](https://medium.com/arckit/claude-code-tips-tricks-2c9b378e28ba) — 10 практических советов

## Context Notes

- Researched on: 2026-03-27
- Sources consulted: 7 (GitHub repo, GitHub API, Medium article, longform guide, shortform guide, web search x2)
- Relevance to current project: **ПРЯМАЯ** — turbo-claude-code создан для тех же целей. Можно заимствовать:
  1. **Структуру rules/** — модульные правила вместо одного CLAUDE.md
  2. **Паттерн hooks** — memory persistence через Stop/SessionStart hooks
  3. **Model selection matrix** — формализовать выбор модели
  4. **MCP optimization** — заменить тяжёлые MCPs на CLI skills
  5. **Continuous learning** — авто-извлечение паттернов в skills
  6. **AgentShield** — security scanning для наших конфигов
  7. **Sequential Phase Architecture** — формализовать pipeline субагентов
