# turbo-claude-code

> Кастомные скилы, хуки и конфиг Claude Code — одной командой на любой машине

---

## Быстрая установка

```bash
curl -fsSL https://raw.githubusercontent.com/mad0ps/turbo-claude-code/main/install.sh | bash
```

Или с предпросмотром (без изменений):

```bash
curl -fsSL https://raw.githubusercontent.com/mad0ps/turbo-claude-code/main/install.sh | bash -s -- --dry-run
```

---

## Что устанавливается

| Артефакт | Куда | Описание |
|----------|------|----------|
| `skills/` | `~/.claude/skills/` | Кастомные скилы для Claude Code |
| `hooks/` | `~/.claude/hooks/` | Bash-хуки (фильтр вывода, напоминания) |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Глобальные правила поведения Claude |
| `rules/learned/` | `~/.claude/rules/learned/` | Универсальные инстинкты (грузятся всегда) |
| `knowledge/` | `~/.claude/knowledge/` | Доменные знания (lazy-load по необходимости) |
| `settings.json` | `~/.claude/settings.json` | Permissions + хуки (мержится с существующим) |
| superpowers plugin | — | `claude plugin install superpowers@superpowers-marketplace` |

---

## Скилы

| Скил | Назначение |
|------|------------|
| `/point` | Атомарный чекпоинт: lint → test → log → commit → push → CI |
| `/reflect` | Извлечь инстинкты → `rules/learned/` (universal) или `knowledge/` (domain) |
| `/finish` | Завершить сессию: /reflect + /save-context |
| `/learn` | Зафиксировать урок |
| `/fact-check` | Проверить факты перед публикацией |
| `/web-research` | Веб-исследование через агентов |
| `/bash-deployer` | Деплой через bash-скрипты |
| `/deploy-check` | Проверка статуса деплоя |
| `/model-selection` | Выбор модели для задачи |
| `/save-context` | Сохранить контекст сессии |

---

## Хуки

- **filter-bash-output.sh** — обрезает вывод >200 строк для экономии токенов (требует python3)
- **stop-reminder.sh** — напоминает запустить /finish перед выходом из сессии

---

## Как работает

Скрипт:
1. Клонирует репо в `~/turbo-claude-code` (или делает `git pull` если уже есть)
2. Создаёт симлинки: `~/.claude/skills/<name>` → репо (per-skill)
3. Создаёт симлинки: `~/.claude/hooks/<name>` → репо
4. Симлинкует `CLAUDE.md`, `rules/learned/` и `knowledge/`
5. Мержит `settings.json` — добавляет permissions и хуки, сохраняя кастомные настройки (python3)
6. Устанавливает superpowers плагин если claude найден

Безопасен для `curl | bash` — обёрнут в `main()` wrapper.

Идемпотентен — можно запускать повторно, существующие конфиги бэкапятся.

---

## Интеграция с turbo-terminal-ios-claude-code

При использовании [turbo-terminal-ios-claude-code](https://github.com/mad0ps/turbo-terminal-ios-claude-code) `setup.sh` автоматически предложит установить turbo-claude-code как опциональный компонент.

---

## Лицензия

MIT
