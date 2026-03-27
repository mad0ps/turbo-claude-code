# Continuous Learning System — Design Spec

## Problem

Claude Code не учится между сессиями. Каждая новая сессия начинается с нуля — те же ошибки, те же вопросы, те же коррекции. Memory system хранит факты, но не поведенческие паттерны.

## Solution

Три компонента: `/reflect` (извлечение instincts), `/finish` (оркестратор), Stop hook (напоминалка).

## Architecture

```
Сессия работы
    ↓
Stop Hook: "Run /finish to save progress"
    ↓
/finish (оркестратор)
    ├── 1. /reflect (пока контекст полный)
    │       ↓ анализ сессии
    │       ↓ извлечение instincts
    │       ↓ запись в domain-файлы
    │
    └── 2. /save-context (фиксация фактов)
            ↓ session-log.md
            ↓ lessons-learned.md
            ↓ отмечает "N instincts extracted"
```

## Components

### 1. `/reflect` skill

**Trigger:** User invokes `/reflect` manually or through `/finish`.

**Анализ сессии — что извлекать:**

| Тип | Сигнал | Пример instinct |
|-----|--------|-----------------|
| Коррекция | "нет", "не так", "стоп", "используй X" | "when Y, use X instead of Z" |
| Рабочий паттерн | Повторяющийся подход, сработавший 2+ раз | "when deploying, always check CI first" |
| Архитектурное решение | "выбрали X потому что Y" | "for this project, use X because Y" |
| Tool preference | Явный или неявный выбор инструмента | "prefer ruff over black for Python" |
| Communication style | Реакция на формат ответа | "keep responses short, no summaries" |

**Алгоритм работы:**

1. Пройти по контексту сессии, найти:
   - Коррекции пользователя (отказы, поправки, "не так")
   - Подтверждения ("да", "отлично", "именно")
   - Повторяющиеся паттерны
   - Явные решения и их причины
2. Для каждого кандидата определить:
   - `domain` — programming, devops, design, security, workflow, tools (или новый)
   - `scope` — global (универсальное) или project (специфичное)
   - `confidence` — 0.5-0.9 по шкале ниже
3. Проверить дедупликацию — прочитать существующие instinct-файлы, не дублировать
4. Если instinct уже существует — поднять confidence (+0.1), обновить дату
5. Записать в нужный domain-файл

**Confidence scale:**

| Сигнал | Confidence |
|--------|-----------|
| Одно наблюдение, неявное | 0.5 |
| Явная коррекция пользователя | 0.7 |
| Подтверждённый паттерн (2+ раза) | 0.8 |
| Прямое указание пользователя "всегда делай X" | 0.9 |

**Минимальный порог:** confidence < 0.5 — не сохранять (слишком слабый сигнал).

**Вывод пользователю:**

```
Extracted N instincts:
  [programming] +new: prefer-explicit-types (0.7)
  [workflow] ↑updated: keep-responses-short (0.7 → 0.8)
  [devops] +new: always-check-ci-before-deploy (0.8)
Saved to: ~/.claude/rules/learned/ (2 global), .claude/rules/learned/ (1 project)
```

### 2. `/finish` skill

**Trigger:** User invokes `/finish` at end of session.

**Поведение:**
1. Вызвать `/reflect` — извлечь instincts (контекст ещё полный)
2. Вызвать `/save-context` — сохранить факты сессии (session-log, lessons-learned, memory)

Это тонкая обёртка. Не добавляет логики — только порядок вызова.

### 3. Stop Hook — напоминалка

**Trigger:** Claude Code Stop event (конец сессии).

**Поведение:** Shell-скрипт, выводит одну строку в stderr:
```
Run /finish to save progress and extract learnings
```

Без анализа, без подсчёта сообщений — просто напоминание. Минимальный overhead.

## Storage

### Двухуровневая структура

**Global instincts** — `~/.claude/rules/learned/`:
```
~/.claude/rules/learned/
├── programming.md      # языки, паттерны кода, тестирование
├── devops.md           # CI/CD, Docker, серверы, деплой
├── design.md           # UI/UX, фронтенд
├── security.md         # security, пентест, hardening
├── workflow.md         # стиль работы, общение, процессы
└── tools.md            # CLI, инструменты, конфигурация
```

Загружаются в КАЖДУЮ сессию. Только по-настоящему универсальное.

**Project instincts** — `<project>/.claude/rules/learned/`:
```
<project>/.claude/rules/learned/
├── architecture.md     # архитектурные решения проекта
└── patterns.md         # conventions и паттерны кодобазы
```

Загружаются только при работе в этом проекте.

### Token Budget — CRITICAL

Rules загружаются в КАЖДУЮ сессию. Каждый лишний токен = деньги × кол-во сессий.

**Жёсткие лимиты:**
- **Все global instinct-файлы суммарно: max 1500 tokens (~100 строк)**
- **Один domain-файл: max 15 instincts**
- **Один instinct: 1 строка** (compact format ниже)

При превышении — `/reflect` обязан сконсолидировать перед добавлением новых.

### Формат instinct — compact one-liner

```markdown
# <Domain> Instincts

<!-- Format: confidence | trigger → action (source, date) -->
0.8 | deploying code → always verify CI before push (correction, 2026-03-28)
0.7 | writing Python → prefer ruff over black (pattern, 2026-03-25)
0.9 | responding to user → keep short, no trailing summaries (correction, 2026-03-20)
```

**Почему one-liner:** 7 строк × 50 instincts = 350 строк. 1 строка × 50 = 50 строк. Экономия 6x.

Заголовок и comment-строка — overhead 2 строки на файл. Всё остальное — данные.

### Domain-файлы создаются лениво

Не создавать все 6 файлов сразу. Файл появляется только когда в этом домене извлечён первый instinct. Пустых файлов не бывает.

### Консолидация — агрессивная

Порог: domain-файл > **15 instincts** (не 50!). `/reflect` при следующем запуске:
- Удалить instincts с confidence < 0.6
- Объединить похожие (merge → один с max confidence)
- Архивировать старые (>2 месяцев без обновления, confidence < 0.7)
- Если после очистки всё ещё >15 — удалить lowest confidence до лимита

**Мониторинг:** `/reflect` при каждом запуске считает total tokens:
```bash
wc -l ~/.claude/rules/learned/*.md  # target: < 100 lines total
```

## Edge Cases

| Ситуация | Поведение |
|----------|-----------|
| Пустая сессия (только вопрос-ответ) | `/reflect` пишет "No instincts to extract" |
| Противоречие с существующим instinct | Обновить instinct, добавить note. Если confidence нового > старого — заменить |
| Слишком много instincts за сессию | Max 10 за один `/reflect`. Приоритет: коррекции > решения > паттерны |
| Domain не подходит ни под один | Создать новый domain-файл (e.g., `ml.md`, `mobile.md`) |
| `/finish` вызван дважды | `/reflect` проверяет дедупликацию, не создаст дубли |
| Token budget exceeded | Принудительная консолидация перед добавлением. Если после консолидации нет места — replace lowest confidence instinct |

## Implementation Scope

| Компонент | Файл | Тип |
|-----------|------|-----|
| `/reflect` | `~/.claude/skills/reflect/SKILL.md` | Skill |
| `/finish` | `~/.claude/skills/finish/SKILL.md` | Skill |
| Stop hook | `~/.claude/settings.json` hooks section | Hook config |
| Global instinct storage | `~/.claude/rules/learned/*.md` | Auto-loaded rules |
| Project instinct storage | `<project>/.claude/rules/learned/*.md` | Auto-loaded rules |

## Success Criteria

1. После `/reflect` — instincts появляются в domain-файлах
2. В следующей сессии — instincts автоматически загружены (видны в поведении Claude)
3. Claude не повторяет ошибки, за которые его поправили
4. **Total instinct storage < 1500 tokens** (~100 строк) — мониторится при каждом `/reflect`
5. `/finish` = один вызов вместо двух
6. **Baseline token overhead от instincts < 2% context window** (< 4K tokens на 200K)
