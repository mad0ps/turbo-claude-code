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
| `rules/learned/` | `~/.claude/rules/learned/` | Накопленные паттерны и инстинкты |
| `settings.json` | `~/.claude/settings.json` | Конфиг хуков (генерируется с правильными путями) |
| superpowers plugin | — | `claude plugin install superpowers@superpowers-marketplace` |

---

## Скилы

| Скил | Назначение |
|------|------------|
| `/point` | Атомарный чекпоинт: lint → test → log → commit → push → CI |
| `/reflect` | Извлечь инстинкты из сессии в `rules/learned/` |
| `/finish` | Завершить ветку разработки |
| `/learn` | Зафиксировать урок |
| `/fact-check` | Проверить факты перед публикацией |
| `/web-research` | Веб-исследование через агентов |
| `/bash-deployer` | Деплой через bash-скрипты |
| `/deploy-check` | Проверка статуса деплоя |
| `/model-selection` | Выбор модели для задачи |
| `/save-context` | Сохранить контекст сессии |

---

## Хуки

- **filter-bash-output.sh** — фильтрует избыточный вывод bash-команд
- **stop-reminder.sh** — напоминание после завершения задачи

---

## Как работает

Скрипт:
1. Клонирует репо в `~/turbo-claude-code` (или делает `git pull` если уже есть)
2. Создаёт симлинки: `~/.claude/skills/<name>` → репо (per-skill)
3. Создаёт симлинки: `~/.claude/hooks/<name>` → репо
4. Симлинкует `CLAUDE.md` и `rules/learned/`
5. Генерирует `settings.json` с хуками (через python3)
6. Устанавливает superpowers плагин если claude найден

Идемпотентен — можно запускать повторно, существующие конфиги бэкапятся.

---

## Интеграция с turbo-terminal-ios-claude-code

При использовании [turbo-terminal-ios-claude-code](https://github.com/mad0ps/turbo-terminal-ios-claude-code) `setup.sh` автоматически предложит установить turbo-claude-code как опциональный компонент.

---

## Лицензия

MIT
