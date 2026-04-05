# DevOps Knowledge

## Instincts
0.8 | deploying via CI/CD → never run build/deploy/restart on servers directly; commit+push, let pipeline handle it (decision, 2026-03-28)
0.7 | checking server logs → use SSH for diagnostics only, exit after reading (decision, 2026-03-28)
0.8 | writing bash install scripts → use set -euo pipefail, main() wrapper, trap ERR, color output, dry-run mode (pattern, 2026-03-29)
0.7 | docker compose changes → always verify with docker compose config before deploying (pattern, 2026-03-29)
0.7 | systemd service files → test with systemd-analyze verify before enabling (pattern, 2026-03-29)
