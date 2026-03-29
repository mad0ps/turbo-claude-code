# Install Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать `turbo-claude-code/install.sh` для переноса скилов/хуков/конфига на сервер одной командой, и добавить опциональный вызов из `turbo-terminal-ios-claude-code/setup.sh`.

**Architecture:** Автономный `install.sh` клонирует репо, создаёт симлинки в `~/.claude/`, генерирует `settings.json` через python3. `setup.sh` получает три точечных дополнения без изменения существующей логики.

**Tech Stack:** bash, git, python3 (для merge JSON)

---

## File Map

**Создать:**
- `turbo-claude-code/CLAUDE.md` — копия глобального `~/.claude/CLAUDE.md`
- `turbo-claude-code/rules/learned/workflow.md` — копия `~/.claude/rules/learned/workflow.md`
- `turbo-claude-code/rules/learned/research.md` — копия `~/.claude/rules/learned/research.md`
- `turbo-claude-code/rules/learned/design.md` — копия `~/.claude/rules/learned/design.md`
- `turbo-claude-code/rules/learned/tools.md` — копия `~/.claude/rules/learned/tools.md`
- `turbo-claude-code/install.sh` — основной установщик

**Изменить:**
- `turbo-terminal-ios-claude-code/setup.sh` — три добавления: вопрос, план, блок выполнения
- `turbo-claude-code/README.md` (создать если нет) — секция "Установка на сервер"
- `turbo-terminal-ios-claude-code/README.md` — упоминание новой опции

---

### Task 1: Добавить CLAUDE.md и rules/learned/ в репо

**Files:**
- Create: `turbo-claude-code/CLAUDE.md`
- Create: `turbo-claude-code/rules/learned/workflow.md`
- Create: `turbo-claude-code/rules/learned/research.md`
- Create: `turbo-claude-code/rules/learned/design.md`
- Create: `turbo-claude-code/rules/learned/tools.md`

- [ ] **Step 1: Скопировать файлы из ~/.claude/**

```bash
cp ~/.claude/CLAUDE.md /path/to/turbo-claude-code/CLAUDE.md
mkdir -p /path/to/turbo-claude-code/rules/learned
cp ~/.claude/rules/learned/workflow.md /path/to/turbo-claude-code/rules/learned/
cp ~/.claude/rules/learned/research.md /path/to/turbo-claude-code/rules/learned/
cp ~/.claude/rules/learned/design.md /path/to/turbo-claude-code/rules/learned/
cp ~/.claude/rules/learned/tools.md /path/to/turbo-claude-code/rules/learned/
```

- [ ] **Step 2: Проверить что файлы скопированы корректно**

```bash
ls turbo-claude-code/rules/learned/
# Ожидается: design.md  research.md  tools.md  workflow.md
cat turbo-claude-code/CLAUDE.md | head -5
# Ожидается: первые строки из ~/.claude/CLAUDE.md
```

- [ ] **Step 3: Добавить rules/ в .gitignore исключение (убедиться что не игнорируется)**

Открыть `turbo-claude-code/.gitignore`, убедиться что `rules/` не исключена. Файл сейчас содержит только `.DS_Store` и `.claude/` — добавлять ничего не нужно.

- [ ] **Step 4: Коммит**

```bash
cd turbo-claude-code
git add CLAUDE.md rules/
git commit -m "feat: add CLAUDE.md and rules/learned for server install"
```

---

### Task 2: Написать install.sh

**Files:**
- Create: `turbo-claude-code/install.sh`

- [ ] **Step 1: Создать файл с шапкой, цветами, dry-run поддержкой**

```bash
cat > turbo-claude-code/install.sh << 'EOF'
#!/bin/bash

# ============================================
# turbo-claude-code installer
# Claude Code skills, hooks, and config setup
# ============================================

set -euo pipefail

trap 'error "Script interrupted (line $LINENO)"' ERR

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "\033[1;33m[DRY-RUN] Preview mode — nothing will be changed\033[0m"
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[✗]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }
EOF
chmod +x turbo-claude-code/install.sh
```

- [ ] **Step 2: Добавить секцию SYSTEM CHECK**

Дописать в `install.sh`:

```bash
# ============================================
# SYSTEM CHECK
# ============================================
header "SYSTEM CHECK"

if ! command -v git &>/dev/null; then
    error "git not found — required"
    exit 1
fi
info "git: $(git --version | awk '{print $NF}')"

if command -v claude &>/dev/null; then
    info "Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
else
    warn "Claude Code not found — install it for skills to work"
fi

HAS_PYTHON=false
if command -v python3 &>/dev/null; then
    info "python3: available (will merge settings.json)"
    HAS_PYTHON=true
else
    warn "python3 not found — settings.json will be created from scratch if missing"
fi
```

- [ ] **Step 3: Добавить секцию REPO (clone / pull)**

Дописать в `install.sh`:

```bash
# ============================================
# REPO
# ============================================
header "REPO"

REPO_URL="https://github.com/mad0ps/turbo-claude-code.git"
REPO_DIR="$HOME/turbo-claude-code"

if [ -d "$REPO_DIR/.git" ]; then
    info "Repo found at $REPO_DIR — pulling latest"
    if [ "$DRY_RUN" = false ]; then
        git -C "$REPO_DIR" pull --ff-only
    else
        info "[DRY-RUN] Would: git pull in $REPO_DIR"
    fi
else
    info "Cloning to $REPO_DIR"
    if [ "$DRY_RUN" = false ]; then
        git clone "$REPO_URL" "$REPO_DIR"
    else
        info "[DRY-RUN] Would: git clone $REPO_URL $REPO_DIR"
    fi
fi
```

- [ ] **Step 4: Добавить секцию SYMLINKS (skills + hooks)**

Дописать в `install.sh`:

```bash
# ============================================
# SYMLINKS
# ============================================
header "SYMLINKS"

mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/hooks"

for skill_path in "$REPO_DIR/skills"/*/; do
    [ -d "$skill_path" ] || continue
    skill_name=$(basename "$skill_path")
    target="$HOME/.claude/skills/$skill_name"
    if [ "$DRY_RUN" = false ]; then
        ln -sfn "$skill_path" "$target"
        info "skills/$skill_name"
    else
        info "[DRY-RUN] Would symlink: skills/$skill_name"
    fi
done

for hook_path in "$REPO_DIR/hooks"/*.sh; do
    [ -f "$hook_path" ] || continue
    hook_name=$(basename "$hook_path")
    target="$HOME/.claude/hooks/$hook_name"
    if [ "$DRY_RUN" = false ]; then
        ln -sfn "$hook_path" "$target"
        info "hooks/$hook_name"
    else
        info "[DRY-RUN] Would symlink: hooks/$hook_name"
    fi
done
```

- [ ] **Step 5: Добавить секцию CONFIG (CLAUDE.md + rules/learned)**

Дописать в `install.sh`:

```bash
# ============================================
# CONFIG
# ============================================
header "CONFIG"

# CLAUDE.md
CLAUDE_SRC="$REPO_DIR/CLAUDE.md"
CLAUDE_DST="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_SRC" ]; then
    if [ "$DRY_RUN" = false ]; then
        if [ -f "$CLAUDE_DST" ] && [ ! -L "$CLAUDE_DST" ]; then
            cp "$CLAUDE_DST" "$CLAUDE_DST.bak.$(date +%Y%m%d-%H%M%S)"
            warn "Backed up existing CLAUDE.md"
        fi
        ln -sfn "$CLAUDE_SRC" "$CLAUDE_DST"
        info "CLAUDE.md symlinked"
    else
        info "[DRY-RUN] Would symlink: CLAUDE.md"
    fi
else
    warn "CLAUDE.md not in repo — skipping"
fi

# rules/learned/
RULES_SRC="$REPO_DIR/rules/learned"
RULES_DST="$HOME/.claude/rules/learned"
if [ -d "$RULES_SRC" ]; then
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/.claude/rules"
        if [ -d "$RULES_DST" ] && [ ! -L "$RULES_DST" ]; then
            mv "$RULES_DST" "$RULES_DST.bak.$(date +%Y%m%d-%H%M%S)"
            warn "Backed up existing rules/learned/"
        fi
        ln -sfn "$RULES_SRC" "$RULES_DST"
        info "rules/learned/ symlinked"
    else
        info "[DRY-RUN] Would symlink: rules/learned/"
    fi
else
    warn "rules/learned/ not in repo — skipping"
fi
```

- [ ] **Step 6: Добавить секцию SETTINGS (генерация/merge settings.json)**

Дописать в `install.sh`:

```bash
# ============================================
# SETTINGS
# ============================================
header "SETTINGS"

SETTINGS_PATH="$HOME/.claude/settings.json"

_generate_settings() {
    python3 - <<PYEOF
import sys, json, os

repo_dir = "$REPO_DIR"
hooks_dir = "$HOME/.claude/hooks"
settings_path = "$SETTINGS_PATH"

if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
else:
    settings = {}

if "permissions" not in settings:
    settings["permissions"] = {
        "allow": ["Bash","Read","Edit","Write","Glob","Grep",
                  "WebFetch","WebSearch","NotebookEdit","Task","Skill"]
    }

settings["hooks"] = {
    "PostToolUse": [{
        "matcher": "Bash",
        "hooks": [{"type": "command",
                   "command": os.path.join(hooks_dir, "filter-bash-output.sh")}]
    }],
    "Stop": [{
        "matcher": "",
        "hooks": [{"type": "command",
                   "command": os.path.join(hooks_dir, "stop-reminder.sh")}]
    }]
}

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
PYEOF
}

_generate_settings_nopy() {
    cat > "$SETTINGS_PATH" << SETTINGS
{
  "permissions": {
    "allow": ["Bash","Read","Edit","Write","Glob","Grep","WebFetch","WebSearch","NotebookEdit","Task","Skill"]
  },
  "hooks": {
    "PostToolUse": [{"matcher":"Bash","hooks":[{"type":"command","command":"$HOME/.claude/hooks/filter-bash-output.sh"}]}],
    "Stop": [{"matcher":"","hooks":[{"type":"command","command":"$HOME/.claude/hooks/stop-reminder.sh"}]}]
  }
}
SETTINGS
}

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$HOME/.claude"
    if [ -f "$SETTINGS_PATH" ]; then
        cp "$SETTINGS_PATH" "$SETTINGS_PATH.bak.$(date +%Y%m%d-%H%M%S)"
        warn "Backed up existing settings.json"
    fi
    if [ "$HAS_PYTHON" = true ]; then
        _generate_settings
        info "settings.json updated (merged)"
    else
        if [ ! -f "$SETTINGS_PATH" ]; then
            _generate_settings_nopy
            info "settings.json created"
        else
            warn "python3 not available — settings.json NOT updated (hooks paths may be wrong)"
        fi
    fi
else
    info "[DRY-RUN] Would generate/merge settings.json"
fi
```

- [ ] **Step 7: Добавить секцию DONE (итоговый вывод)**

Дописать в `install.sh`:

```bash
# ============================================
# DONE
# ============================================
header "DONE"

info "turbo-claude-code installed!"
echo ""
echo "  Skills:    ~/.claude/skills/ → $REPO_DIR/skills/"
echo "  Hooks:     ~/.claude/hooks/  → $REPO_DIR/hooks/"
echo "  CLAUDE.md: ~/.claude/CLAUDE.md"
echo "  rules/:    ~/.claude/rules/learned/"
echo "  settings:  ~/.claude/settings.json"
echo ""
if command -v claude &>/dev/null; then
    info "Start: claude"
else
    warn "Install Claude Code: curl -fsSL https://claude.ai/install.sh | bash"
fi
```

- [ ] **Step 8: Убедиться что файл исполняемый**

```bash
chmod +x turbo-claude-code/install.sh
```

---

### Task 3: Проверить install.sh с --dry-run

**Files:**
- Test: `turbo-claude-code/install.sh`

- [ ] **Step 1: Запустить dry-run**

```bash
bash turbo-claude-code/install.sh --dry-run
```

Ожидается вывод всех секций с `[DRY-RUN] Would:` без изменения файлов, без ошибок.

- [ ] **Step 2: Убедиться что ~/.claude/ не изменился**

```bash
ls -la ~/.claude/skills/ | head -5
# Симлинки не изменились — dry-run не трогает файлы
```

- [ ] **Step 3: Коммит**

```bash
cd turbo-claude-code
git add install.sh
git commit -m "feat: add install.sh for one-command server setup"
```

---

### Task 4: Добавить INSTALL_TURBO в setup.sh

**Files:**
- Modify: `turbo-terminal-ios-claude-code/setup.sh`

Три точки вставки, каждая независима.

- [ ] **Step 1: Добавить вопрос после блока INSTALL_AGENT_PERMS**

Найти строку:
```bash
# Проверка git для плагинов
```

Вставить перед ней:

```bash
INSTALL_TURBO=false
if command -v git &>/dev/null || [ "$GIT_INSTALLED" = true ]; then
    echo ""
    read -p "Скилы и конфиг Claude Code (turbo-claude-code)? [Y/n]: " choice
    choice=${choice:-y}
    [ "$choice" = "y" ] && INSTALL_TURBO=true
fi

```

- [ ] **Step 2: Добавить строку в ПЛАН УСТАНОВКИ**

Найти строку:
```bash
[ "$INSTALL_AGENT_PERMS" = true ] && echo "  → Расширенные разрешения Claude Code (без подтверждений)"
```

Добавить после неё:
```bash
[ "$INSTALL_TURBO" = true ] && echo "  → Скилы и конфиг Claude Code (turbo-claude-code)"
```

- [ ] **Step 3: Добавить блок выполнения после секции РАЗРЕШЕНИЯ CLAUDE CODE**

Найти строку:
```bash
    info "Расширенные разрешения установлены в ~/.claude/settings.json"
fi

# ============================================
# АЛИАСЫ + МЕНЮ ЛОГИНА
```

Вставить между `fi` и `# АЛИАСЫ`:

```bash
if [ "$INSTALL_TURBO" = true ]; then
    header "CLAUDE CODE СКИЛЫ"
    TURBO_DIR="$HOME/turbo-claude-code"
    if [ -d "$TURBO_DIR/.git" ]; then
        info "Обновляем репо"
        git -C "$TURBO_DIR" pull --ff-only
    else
        info "Клонируем turbo-claude-code"
        git clone https://github.com/mad0ps/turbo-claude-code.git "$TURBO_DIR"
    fi
    if [ -f "$TURBO_DIR/install.sh" ]; then
        bash "$TURBO_DIR/install.sh"
    else
        error "install.sh не найден в $TURBO_DIR"
    fi
fi

```

- [ ] **Step 4: Коммит setup.sh**

```bash
cd turbo-terminal-ios-claude-code
git add setup.sh
git commit -m "feat: add turbo-claude-code skills install option"
```

---

### Task 5: Проверить setup.sh --dry-run с новой опцией

**Files:**
- Test: `turbo-terminal-ios-claude-code/setup.sh`

- [ ] **Step 1: Запустить dry-run**

```bash
bash turbo-terminal-ios-claude-code/setup.sh --dry-run
```

Ожидается: в "ПЛАН УСТАНОВКИ" появляется строка про turbo-claude-code, скрипт завершается без ошибок.

- [ ] **Step 2: Проверить что синтаксис bash валиден**

```bash
bash -n turbo-terminal-ios-claude-code/setup.sh
# Ожидается: нет вывода (нет ошибок)
```

---

### Task 6: Обновить README в обоих репо

**Files:**
- Modify: `turbo-claude-code/README.md` (создать если нет)
- Modify: `turbo-terminal-ios-claude-code/README.md`

- [ ] **Step 1: Добавить/создать README для turbo-claude-code**

Если `turbo-claude-code/README.md` не существует — создать. Если существует — добавить секцию.

Добавить секцию "Установка на сервер":

```markdown
## Установка на сервер

Одна команда — клонирует репо и настраивает `~/.claude/`:

```bash
curl -fsSL https://raw.githubusercontent.com/mad0ps/turbo-claude-code/main/install.sh | bash
```

Что устанавливается:
- `~/.claude/skills/` — симлинки на все скилы из репо
- `~/.claude/hooks/` — симлинки на хуки
- `~/.claude/CLAUDE.md` — глобальные правила поведения
- `~/.claude/rules/learned/` — выученные паттерны
- `~/.claude/settings.json` — permissions + hooks (генерируется с правильными путями)

Поддерживает `--dry-run` для предварительного просмотра.
```

- [ ] **Step 2: Добавить упоминание в turbo-terminal-ios-claude-code/README.md**

Найти таблицу с компонентами (`| **Claude Code** |`) и добавить строку:

```markdown
| **turbo-claude-code** | Скилы, хуки и конфиг Claude Code (опционально) |
```

- [ ] **Step 3: Коммит README**

```bash
cd turbo-claude-code
git add README.md
git commit -m "docs: add server install instructions"

cd ../turbo-terminal-ios-claude-code
git add README.md
git commit -m "docs: mention turbo-claude-code option in setup"
```

---

### Task 7: Push обоих репо

- [ ] **Step 1: Push turbo-claude-code**

```bash
cd turbo-claude-code
git push origin main
```

- [ ] **Step 2: Push turbo-terminal-ios-claude-code**

```bash
cd turbo-terminal-ios-claude-code
git push origin main
```

- [ ] **Step 3: Проверить что raw URL install.sh доступен**

```bash
curl -fsSL https://raw.githubusercontent.com/mad0ps/turbo-claude-code/main/install.sh | head -5
# Ожидается: первые строки install.sh (#!/bin/bash ...)
```
