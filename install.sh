#!/bin/bash

# ============================================
# turbo-claude-code Installer
# One-command setup for Claude Code skills, hooks, and config
# ============================================

set -euo pipefail

trap 'error "Script interrupted (line $LINENO)"' ERR

# ============================================
# DRY-RUN MODE
# ============================================

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "\033[1;33m[DRY-RUN] Preview mode — nothing will be changed\033[0m"
    echo ""
fi

# ============================================
# COLORS AND FUNCTIONS
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
header() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

# ============================================
# SYSTEM CHECK
# ============================================

header "SYSTEM CHECK"

# git (required)
if command -v git &>/dev/null; then
    GIT_VERSION=$(git --version | awk '{print $NF}')
    info "git: $GIT_VERSION"
    HAS_GIT=true
else
    error "git: not found (REQUIRED)"
    exit 1
fi

# claude (warn if missing)
if command -v claude &>/dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
    info "claude: $CLAUDE_VERSION"
    HAS_CLAUDE=true
else
    warn "claude: not found (optional, you can install later)"
    HAS_CLAUDE=false
fi

# python3 (for settings.json merge)
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version | awk '{print $NF}')
    info "python3: $PYTHON_VERSION"
    HAS_PYTHON=true
else
    warn "python3: not found (will use basic JSON fallback)"
    HAS_PYTHON=false
fi

# ============================================
# REPO SETUP
# ============================================

header "REPOSITORY"

if [ -d "$HOME/turbo-claude-code/.git" ]; then
    info "Repository already cloned"
    if [ "$DRY_RUN" = false ]; then
        cd "$HOME/turbo-claude-code"
        git pull --ff-only || warn "Failed to pull latest changes"
        cd - > /dev/null
    else
        echo "[DRY-RUN] Would run: cd ~/turbo-claude-code && git pull --ff-only"
    fi
else
    info "Cloning turbo-claude-code repository..."
    if [ "$DRY_RUN" = false ]; then
        git clone https://github.com/mad0ps/turbo-claude-code.git "$HOME/turbo-claude-code" || {
            error "Failed to clone repository"
            exit 1
        }
    else
        echo "[DRY-RUN] Would run: git clone https://github.com/mad0ps/turbo-claude-code.git ~/turbo-claude-code"
    fi
fi

REPO_DIR="$HOME/turbo-claude-code"
info "Repository: $REPO_DIR"

# ============================================
# SYMLINKS: SKILLS AND HOOKS
# ============================================

header "SYMLINKS: SKILLS AND HOOKS"

mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/hooks"

# Skills
if [ -d "$REPO_DIR/skills" ]; then
    for skill_dir in "$REPO_DIR/skills"/*/; do
        skill_name=$(basename "$skill_dir")
        target="$HOME/.claude/skills/$skill_name"

        if [ "$DRY_RUN" = false ]; then
            ln -sfn "$skill_dir" "$target"
            info "Symlinked skill: $skill_name"
        else
            echo "[DRY-RUN] Would symlink: $skill_dir -> $target"
        fi
    done
else
    warn "Skills directory not found in repo"
fi

# Hooks
if [ -d "$REPO_DIR/hooks" ]; then
    for hook_file in "$REPO_DIR/hooks"/*.sh; do
        if [ -f "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            target="$HOME/.claude/hooks/$hook_name"

            if [ "$DRY_RUN" = false ]; then
                ln -sfn "$hook_file" "$target"
                info "Symlinked hook: $hook_name"
            else
                echo "[DRY-RUN] Would symlink: $hook_file -> $target"
            fi
        fi
    done
else
    warn "Hooks directory not found in repo"
fi

# ============================================
# CONFIG: CLAUDE.MD AND RULES
# ============================================

header "CONFIG: CLAUDE.MD AND RULES"

# CLAUDE.md
if [ -f "$REPO_DIR/CLAUDE.md" ]; then
    if [ "$DRY_RUN" = false ]; then
        if [ -f "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
            backup_file="$HOME/.claude/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
            cp "$HOME/.claude/CLAUDE.md" "$backup_file"
            warn "Backed up existing CLAUDE.md to $backup_file"
        fi

        ln -sfn "$REPO_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
        info "Symlinked CLAUDE.md"
    else
        echo "[DRY-RUN] Would symlink CLAUDE.md: $REPO_DIR/CLAUDE.md -> ~/.claude/CLAUDE.md"
    fi
else
    warn "CLAUDE.md not found in repo"
fi

# rules/learned
if [ -d "$REPO_DIR/rules/learned" ]; then
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/.claude/rules"

        if [ -d "$HOME/.claude/rules/learned" ] && [ ! -L "$HOME/.claude/rules/learned" ]; then
            backup_dir="$HOME/.claude/rules/learned.backup-$(date +%Y%m%d-%H%M%S)"
            mv "$HOME/.claude/rules/learned" "$backup_dir"
            warn "Backed up existing rules/learned to $backup_dir"
        fi

        ln -sfn "$REPO_DIR/rules/learned" "$HOME/.claude/rules/learned"
        info "Symlinked rules/learned"
    else
        echo "[DRY-RUN] Would symlink rules/learned: $REPO_DIR/rules/learned -> ~/.claude/rules/learned"
    fi
else
    warn "rules/learned not found in repo"
fi

# ============================================
# SETTINGS: GENERATE OR MERGE settings.json
# ============================================

header "SETTINGS"

SETTINGS_PATH="$HOME/.claude/settings.json"

_generate_settings() {
    if [ "$HAS_PYTHON" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would generate/merge settings.json with hooks"
            return
        fi

        # Backup existing file if needed
        if [ -f "$SETTINGS_PATH" ] && [ ! -L "$SETTINGS_PATH" ]; then
            backup_file="$SETTINGS_PATH.backup-$(date +%Y%m%d-%H%M%S)"
            cp "$SETTINGS_PATH" "$backup_file"
            warn "Backed up existing settings.json to $backup_file"
        fi

        # Use python3 to merge/generate settings.json
        python3 << PYEOF
import json
import os

settings_path = "$SETTINGS_PATH"
repo_dir = "$REPO_DIR"
home_dir = "$HOME"

# Load existing settings or start fresh
try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

# Ensure permissions.allow list exists
if 'permissions' not in settings:
    settings['permissions'] = {}
if 'allow' not in settings['permissions']:
    settings['permissions']['allow'] = []

# Always update hooks section with correct paths
if 'hooks' not in settings:
    settings['hooks'] = {}

settings['hooks'] = {
    'PostToolUse': [
        {
            'matcher': 'Bash',
            'hooks': [{'type': 'command', 'command': f'{home_dir}/.claude/hooks/filter-bash-output.sh'}]
        }
    ],
    'Stop': [
        {
            'matcher': '',
            'hooks': [{'type': 'command', 'command': f'{home_dir}/.claude/hooks/stop-reminder.sh'}]
        }
    ]
}

# Write updated settings
os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
PYEOF

        info "Generated/merged settings.json"
    fi
}

_generate_settings_nopy() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would generate settings.json (basic fallback)"
        return
    fi

    if [ ! -f "$SETTINGS_PATH" ]; then
        mkdir -p "$HOME/.claude"
        cat > "$SETTINGS_PATH" << SETTINGS
{
  "permissions": {
    "allow": ["Bash","Read","Edit","Write","Glob","Grep","WebFetch","WebSearch","NotebookEdit","Task","Skill"]
  },
  "hooks": {
    "PostToolUse": [{"matcher":"Bash","hooks":[{"type":"command","command":"\$HOME/.claude/hooks/filter-bash-output.sh"}]}],
    "Stop": [{"matcher":"","hooks":[{"type":"command","command":"\$HOME/.claude/hooks/stop-reminder.sh"}]}]
  }
}
SETTINGS
        info "Generated minimal settings.json"
    else
        warn "settings.json exists but python3 not available — NOT updating (manual merge may be needed)"
    fi
}

if [ "$HAS_PYTHON" = true ]; then
    _generate_settings
else
    _generate_settings_nopy
fi

# ============================================
# DONE
# ============================================

header "DONE!"

if [ "$DRY_RUN" = true ]; then
    echo "Dry-run complete. To install for real, run: bash $0"
else
    echo -e "${BOLD}Installation complete!${NC}\n"

    echo "Installed:"
    echo "  → Skills in ~/.claude/skills/"
    echo "  → Hooks in ~/.claude/hooks/"
    echo "  → CLAUDE.md rules in ~/.claude/CLAUDE.md"
    echo "  → Learned patterns in ~/.claude/rules/learned/"
    echo "  → settings.json hooks configured"
    echo ""

    if [ "$HAS_CLAUDE" = false ]; then
        echo "Next step:"
        echo "  → Install Claude Code: curl -fsSL https://claude.ai/install.sh | bash"
    else
        echo "All set! Start using:"
        echo "  → claude         (Claude Code CLI)"
        echo "  → /point         (checkpoint skill)"
        echo "  → /reflect       (extract instincts)"
    fi
fi
