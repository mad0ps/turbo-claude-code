# turbo-claude-code

## Что это
Репо с кастомными skills, hooks, rules и knowledge для Claude Code. Source of truth — всё в ~/.claude/ через симлинки.

## Стек
Bash / Python (хуки) / Markdown (skills, rules, knowledge)

## Где живёт
- Репо: github.com/mad0ps/turbo-claude-code
- Локально: ~/Documents/pr0j3cts/turbo-claude-code/
- Симлинки: ~/.claude/hooks/ → repo/hooks/, ~/.claude/skills/ → repo/skills/

## Структура
```
hooks/          ← shell-скрипты, симлинки в ~/.claude/hooks/
skills/         ← кастомные skills (lazy-load)
rules/learned/  ← компактные инстинкты (всегда загружаются)
knowledge/      ← доменные знания (lazy-load)
install.sh      ← полная установка с нуля
```

## Как деплоить изменения
```bash
# Изменил хук или скрипт:
git add <file> && git commit -m "..." && git push
# Симлинки уже указывают на repo — изменения применяются мгновенно
```

## Правила
- Симлинки — source of truth. НЕ редактировать файлы напрямую в ~/.claude/ если они симлинки
- skills/ — писать на английском (экономия токенов)
- После добавления нового хука — зарегистрировать в ~/.claude/settings.json
- После добавления superpowers skills — install.sh обновит симлинки (sort -V → latest)

## Известные грабли
- PostToolUse формат: `{"continue": true}` — НЕ `{"decision":"allow"}` (API изменился)
- SessionStart hook stdout → инжектируется в контекст Claude автоматически
- superpowers skill symlinks НЕ обновляются автоматически при обновлении плагина → запустить install.sh
