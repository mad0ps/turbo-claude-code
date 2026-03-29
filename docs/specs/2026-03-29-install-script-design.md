# Install Script Design

**Date:** 2026-03-29
**Scope:** `turbo-claude-code/install.sh` + добавление секции в `turbo-terminal-ios-claude-code/setup.sh`

## Цель

Перенос кастомных скилов, хуков и конфига Claude Code на любой сервер одной командой:

```bash
curl -fsSL https://raw.githubusercontent.com/mad0ps/turbo-claude-code/main/install.sh | bash
```

## Архитектура

Два файла, чёткое разделение ответственности:

- `turbo-claude-code/install.sh` — автономный установщик Claude Code конфига
- `turbo-terminal-ios-claude-code/setup.sh` — terminal setup, опционально вызывает install.sh

## turbo-claude-code/install.sh

### Шаги выполнения

```
1. Анализ системы   — git, claude, python3 (для merge settings.json)
2. Клонирование     — git clone → ~/turbo-claude-code; если есть — git pull
3. Симлинки skills  — ~/.claude/skills/<name> → repo/skills/<name> (per-skill)
4. Симлинки hooks   — ~/.claude/hooks/<name> → repo/hooks/<name> (per-hook)
5. CLAUDE.md        — симлинк repo/CLAUDE.md → ~/.claude/CLAUDE.md (бэкап если существует)
6. rules/learned/   — симлинк repo/rules/learned/ → ~/.claude/rules/learned/ (бэкап если существует)
7. settings.json    — генерация/merge с правильными путями к хукам
8. Итог             — сводка: что поставлено, что пропущено
```

### settings.json

Генерируется через python3 динамически — пути к хукам берутся из реального расположения репо на текущей машине.

- Если `~/.claude/settings.json` **не существует** → создаётся с нуля
- Если **существует** → мержится: обновляются только секции `hooks` и добавляются `permissions` если отсутствуют; остальное не трогается

### Новые файлы добавляемые в репо

До написания install.sh нужно добавить в `turbo-claude-code`:
- `CLAUDE.md` — скопировать из `~/.claude/CLAUDE.md`
- `rules/learned/` — скопировать папку из `~/.claude/rules/learned/`

После этого install.sh симлинкует их на целевой машине.

### Что включается в репо (публичный GitHub)

| Артефакт | В репо | Причина |
|---|---|---|
| `skills/` | ✅ | Markdown, нет секретов |
| `hooks/` | ✅ | Bash скрипты, нет секретов |
| `CLAUDE.md` | ✅ | Правила поведения, нет секретов |
| `rules/learned/` | ✅ | Паттерны и инстинкты, нет секретов |
| `settings.json` | ❌ | Хардкодные пути, генерируется на месте |
| `memory/` | ❌ | Личные заметки |

### Идемпотентность

Скрипт можно запускать повторно — существующие симлинки перезаписываются, бэкап берётся только при первом запуске если оригинальный файл существует.

### Стиль

Совпадает с `setup.sh`: те же цвета, функции `info/warn/error/header`, поддержка `--dry-run`.

## Изменения в setup.sh

Три точечных добавления, ничего не ломается:

**1. Блок "ЧТО СТАВИМ?"** — новая переменная и вопрос:
```bash
INSTALL_TURBO=false
read -p "Скилы и конфиг Claude Code (turbo-claude-code)? [Y/n]: " choice
choice=${choice:-y}
[ "$choice" = "y" ] && INSTALL_TURBO=true
```

**2. Блок "ПЛАН УСТАНОВКИ"** — новая строка:
```bash
[ "$INSTALL_TURBO" = true ] && echo "  → Скилы и конфиг Claude Code (turbo-claude-code)"
```

**3. Новый блок выполнения** после секции "РАЗРЕШЕНИЯ CLAUDE CODE":
```bash
if [ "$INSTALL_TURBO" = true ]; then
    header "CLAUDE CODE СКИЛЫ"
    # клонирует turbo-claude-code и запускает install.sh
fi
```

## Документация

- `turbo-claude-code/README.md` — добавить секцию "Установка на сервер" с одной командой
- `turbo-terminal-ios-claude-code/README.md` — упомянуть новую опцию в описании setup.sh

## Git

После реализации: коммит в оба репо, push.
