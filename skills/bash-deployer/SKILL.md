---
name: bash-deployer
description: Use when writing or reviewing bash scripts that deploy, install, or configure software on remote or local servers. Covers interactive installers, server deployers, auto-setup scripts. Provides battle-tested patterns from Docker, Pi-hole, XRay, WireGuard installers.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, WebSearch, WebFetch
user-invocable: true
context: fork
agent: general-purpose
argument-hint: "[task description or file to review]"
---

# Bash Deployer/Installer Skill

Write or review bash deployment scripts using battle-tested patterns from production installers (Docker, Pi-hole, XRay, WireGuard, Oh My Zsh, nvm).

**Reference:** `docs/bash-installer-patterns.md` in voidroute project (2500+ lines, full code examples). Read it for detailed patterns.

## When writing a new script or reviewing existing one, enforce ALL rules below.

---

## 1. Script Structure

```bash
#!/usr/bin/env bash
# Script description
# Usage, license, etc.

set -euo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# All function definitions here...

main() {
    parse_args "$@"
    setup_colors
    # ...
}

# Prevents partial execution on truncated `curl | bash` download
main "$@"
```

**Rules:**
- `main()` wrapper ALWAYS — prevents partial execution
- `set -euo pipefail` ALWAYS
- `readonly` for constants
- Functions before main, main at bottom

---

## 2. NEVER guess system behavior. ALWAYS detect.

### OS/Distro — source /etc/os-release (NOT lsb_release)

```bash
detect_os() {
    [[ -r /etc/os-release ]] || { log_error "Cannot detect OS"; exit 1; }
    # shellcheck source=/dev/null
    source /etc/os-release
    DISTRO="${ID}"           # "ubuntu", "debian"
    DISTRO_VERSION="${VERSION_ID}"  # "22.04", "24.04"
    DISTRO_CODENAME="${VERSION_CODENAME:-unknown}"
}
```

### SSH service name — detect, don't assume

```bash
detect_ssh_service() {
    if systemctl is-active --quiet ssh.socket 2>/dev/null; then
        SSH_MODE="socket"   # Ubuntu 22.10+
    elif systemctl list-unit-files ssh.service 2>/dev/null | grep -q ssh.service; then
        SSH_MODE="service"  # Ubuntu classic
        SSH_SERVICE="ssh"
    elif systemctl list-unit-files sshd.service 2>/dev/null | grep -q sshd.service; then
        SSH_MODE="service"  # RHEL/CentOS
        SSH_SERVICE="sshd"
    else
        log_error "Cannot detect SSH service"
        exit 1
    fi
}
```

### Network interface — ask the kernel

```bash
detect_main_interface() {
    MAIN_IF=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
    [[ -n "$MAIN_IF" ]] || { log_error "Cannot detect network interface"; exit 1; }
}
```

### Public IP — fallback chain

```bash
detect_public_ip() {
    PUBLIC_IP=$(curl -4 -s --max-time 5 https://icanhazip.com/ 2>/dev/null) ||
    PUBLIC_IP=$(curl -4 -s --max-time 5 https://api.ipify.org 2>/dev/null) ||
    PUBLIC_IP=$(curl -4 -s --max-time 5 https://ifconfig.me 2>/dev/null) ||
    { log_error "Cannot detect public IP"; exit 1; }
}
```

---

## 3. Colors — terminal-safe (Pi-hole pattern)

```bash
setup_colors() {
    if [[ -t 1 ]]; then
        RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'
        CYAN='\e[1;34m'; BOLD='\e[1m'; DIM='\e[2m'; NC='\e[0m'
    else
        RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; DIM=''; NC=''
    fi
    TICK="[${GREEN}✓${NC}]"
    CROSS="[${RED}✗${NC}]"
    WARN="[${YELLOW}!${NC}]"
    OVER="\\r\\033[K"
}

log_info()    { printf "  %b %s\\n" "${TICK}" "$*"; }
log_warn()    { printf "  %b %s\\n" "${WARN}" "$*"; }
log_error()   { printf "  %b %s\\n" "${CROSS}" "$*" >&2; }
log_start()   { printf "  [i] %s..." "$*"; }
log_done()    { printf "%b  %b %s\\n" "${OVER}" "${TICK}" "$*"; }
log_fail()    { printf "%b  %b %s\\n" "${OVER}" "${CROSS}" "$*" >&2; }
die()         { log_error "$*"; exit 1; }
```

---

## 4. SSH Port Change — Ubuntu 22.04 vs 24.04

**THIS IS CRITICAL. Different Ubuntu versions require different approaches.**

```bash
change_ssh_port() {
    local new_port=$1

    # Always update sshd_config (works on 22.04, backup on 24.04)
    sed -i "s/^#\\?Port .*/Port ${new_port}/" /etc/ssh/sshd_config

    # Override cloud-init
    printf 'Port %s\nPasswordAuthentication no\n' "${new_port}" \
        > /etc/ssh/sshd_config.d/99-custom.conf

    if systemctl is-active --quiet ssh.socket 2>/dev/null; then
        # Ubuntu 24.04+: socket activation — Port in sshd_config is IGNORED
        # Must use socket drop-in
        mkdir -p /etc/systemd/system/ssh.socket.d
        printf '[Socket]\nListenStream=\nListenStream=%s\n' "${new_port}" \
            > /etc/systemd/system/ssh.socket.d/listen.conf
        systemctl daemon-reload
        systemctl restart ssh.socket
    else
        # Ubuntu 22.04: classic — sshd reads Port from config
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    fi
}
```

**Key facts (documented, not guessed):**
- Ubuntu 24.04: `ssh.socket` defines the listening port, NOT sshd_config
- `ListenStream=` (empty) MUST precede new value to clear inherited port
- `KillMode=process` in ssh.service — existing connections survive restart
- `systemctl daemon-reload` REQUIRED before restart (bug LP#2069041)

---

## 5. Idempotent Configuration

**NEVER blindly append. ALWAYS check first.**

```bash
# BAD:
echo "HISTFILE=/dev/null" >> /root/.bashrc

# GOOD:
grep -q 'HISTFILE=/dev/null' /root/.bashrc 2>/dev/null || \
    echo "HISTFILE=/dev/null" >> /root/.bashrc
```

For sysctl:
```bash
ensure_sysctl() {
    local key=$1 value=$2
    grep -q "^${key}" /etc/sysctl.d/99-custom.conf 2>/dev/null || \
        echo "${key}=${value}" >> /etc/sysctl.d/99-custom.conf
}
```

For mounts:
```bash
mountpoint -q /var/log || mount -t tmpfs -o size=50M tmpfs /var/log
```

---

## 6. set -e Safety Rules

**These patterns WILL crash your script under set -e:**

```bash
# BAD — if $fail is false, returns 1, set -e kills script
$fail && err "message"

# BAD — if condition is false, returns 1 at end of function
[[ "$x" == "y" ]] && do_something

# GOOD:
if $fail; then err "message"; fi
if [[ "$x" == "y" ]]; then do_something; fi
```

**Rule:** NEVER use `$var && cmd` or `[[ ]] && cmd` as the LAST statement in a function or if-body. Use explicit `if/then/fi`.

The `&&`/`||` chain itself is exempt from set -e, but the function/block return code IS checked by set -e in the caller.

---

## 7. Remote Execution via SSH

### Base64 encoding for quoting safety

```bash
run_remote() {
    local host=$1; shift
    local encoded
    encoded=$(printf '%s' "$*" | base64 | tr -d '\n')
    ssh "$host" "echo '${encoded}' | base64 -d | bash"
}
```

- `tr -d '\n'` — GNU base64 adds line breaks every 76 chars, macOS doesn't
- Single quotes around encoded string — safe (base64 = A-Za-z0-9+/=)

### SSH connection multiplexing (for multi-command sessions)

```bash
setup_ssh_multiplex() {
    SSH_SOCKET="/tmp/ssh-mux-%r@%h:%p"
    ssh -fNM -o ControlPath="$SSH_SOCKET" "$host"
}

run_on() {
    ssh -o ControlPath="$SSH_SOCKET" "$host" "$@"
}

cleanup_ssh() {
    ssh -o ControlPath="$SSH_SOCKET" -O exit "$host" 2>/dev/null || true
}
```

### ProxyJump SSH config (for multi-hop)

```bash
gen_ssh_config() {
    local config_file=$1
    cat > "$config_file" << EOF
Host vr-*
    User root
    IdentityFile ${KEY_PATH}
    StrictHostKeyChecking no

Host vr-0
    HostName ${SERVERS[0]}
    Port ${PORTS[0]:-22}
EOF
    for i in $(seq 1 $((${#SERVERS[@]}-1))); do
        cat >> "$config_file" << EOF
Host vr-$i
    HostName ${SERVERS[$i]}
    Port ${PORTS[$i]:-22}
    ProxyJump vr-$((i-1))
EOF
    done
}
```

---

## 8. Package Installation

### With retry (DESIGN.md pattern)

```bash
install_packages() {
    local pkgs=("$@")
    local str="Installing ${pkgs[*]}"
    log_start "${str}"

    export DEBIAN_FRONTEND=noninteractive
    if apt-get update -qq && apt-get install -y -qq "${pkgs[@]}" > /dev/null 2>&1; then
        log_done "${str}"
    else
        log_warn "Retrying package install..."
        sleep 3
        if apt-get update -qq && apt-get install -y -qq "${pkgs[@]}" > /dev/null 2>&1; then
            log_done "${str} (retry succeeded)"
        else
            log_fail "${str}"
            return 1
        fi
    fi
}
```

---

## 9. Input Validation

### IP address (angristan WireGuard pattern)

```bash
validate_ip() {
    local ip=$1
    if [[ ! "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        die "Invalid IP: $ip"
    fi
}
```

### Port number

```bash
validate_port() {
    local port=$1
    if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        die "Invalid port: $port"
    fi
}
```

### Interactive prompt with validation loop (angristan pattern)

```bash
prompt_validated() {
    local prompt=$1 var_name=$2 validate_fn=$3 default=${4:-}
    local value
    while true; do
        read -rp "$prompt" value
        value="${value:-$default}"
        if "$validate_fn" "$value" 2>/dev/null; then
            eval "$var_name='$value'"
            return 0
        fi
        log_warn "Invalid input. Try again."
    done
}
```

---

## 10. Cleanup & Signal Handling

```bash
CLEANUP_FILES=()

cleanup() {
    local exit_code=$?
    # Remove temp files
    for f in "${CLEANUP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null
    done
    # Remove SSH control sockets
    rm -f /tmp/ssh-mux-* 2>/dev/null
    exit "$exit_code"
}

trap cleanup EXIT
trap 'echo ""; die "Interrupted"' INT TERM

# Register temp files:
tmpfile=$(mktemp)
CLEANUP_FILES+=("$tmpfile")
```

---

## 11. UFW Firewall

```bash
configure_firewall() {
    local ports=("$@")  # e.g. "22222/tcp" "51820/udp"
    command -v ufw &>/dev/null || return 0

    ufw --force reset > /dev/null 2>&1
    ufw default deny incoming > /dev/null 2>&1
    for port_proto in "${ports[@]}"; do
        ufw allow "$port_proto" > /dev/null 2>&1
    done
    ufw --force enable > /dev/null 2>&1
}
```

**Facts:**
- `ufw --force reset` disables UFW, clears rules, restores default before.rules
- Default before.rules has `ESTABLISHED,RELATED -j ACCEPT` — existing connections survive
- conntrack table NOT cleared by reset — established TCP survives
- `iptables-restore` is atomic — no gap between load and policy apply

---

## 12. Service Management

### Restart with detection

```bash
restart_service() {
    local service=$1
    log_start "Restarting ${service}"
    if systemctl restart "$service" 2>/dev/null; then
        log_done "Restarted ${service}"
    else
        log_fail "Failed to restart ${service}"
        systemctl status "$service" --no-pager 2>&1 | head -5 >&2
        return 1
    fi
}
```

### Enable + start

```bash
enable_service() {
    local service=$1
    systemctl enable "$service" 2>/dev/null
    systemctl start "$service" 2>/dev/null
}
```

---

## 13. Checklist — Review ANY bash deployer script against this

Before approving any bash deployer/installer script, verify:

- [ ] `main()` wrapper at bottom
- [ ] `set -euo pipefail`
- [ ] OS detection via `/etc/os-release` (not `lsb_release`)
- [ ] SSH service detection (socket vs service, ssh vs sshd)
- [ ] Colors disabled when not a TTY (`[[ -t 1 ]]`)
- [ ] No `$var && cmd` as last statement in function
- [ ] All config appends are idempotent (`grep -q` before `echo >>`)
- [ ] Package installs have retry
- [ ] Input validation (IP, port, strings)
- [ ] Temp files cleaned up via trap
- [ ] No hardcoded service names (detect ssh vs sshd)
- [ ] No hardcoded interface names (detect via ip route)
- [ ] Heredocs: quoted `'EOF'` for literal, unquoted `EOF` for expansion
- [ ] base64 piped through `tr -d '\n'` for GNU compat
- [ ] sed anchored with `^` to avoid matching substrings
- [ ] SSH port changes handle both socket activation and classic mode
- [ ] UFW rules: targeted delete in cleanup, not `iptables -F`
- [ ] Secrets never in command args (use env vars or files)
- [ ] `|| true` on commands that may legitimately fail

---

## Usage

When the user asks to write or review a bash deployer/installer:

1. Read this skill's rules
2. If reviewing: read the script, check against the checklist (section 13)
3. If writing: follow all patterns above, detect everything, assume nothing
4. Reference `docs/bash-installer-patterns.md` for detailed code examples
