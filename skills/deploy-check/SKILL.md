---
name: deploy-check
description: Check deployment status of a project. Use when Khan asks if something is running, healthy, or deployed.
allowed-tools: Bash, Read, Grep, Glob
user-invocable: true
argument-hint: "[project-name]"
---

## Deployment Status Check

Check the deployment status of project: $ARGUMENTS

### For each project, check:
1. **GitHub Actions**: `gh run list -R mad0ps/$ARGUMENTS --limit 3`
2. **Docker containers**: Check if running on target VPS (if accessible)
3. **Health endpoint**: curl the health URL if known
4. **Recent commits**: `gh api repos/mad0ps/$ARGUMENTS/commits?per_page=3`

### Known projects and their health URLs:
- **calendar-assistant-saas (CalendAI)**: BASE_URL/health (VPS from GitHub Secrets)
- **andys-support**: check GitHub Actions status
- **social-radar-auto**: local Docker on this server

### Output Format
- Status: UP / DOWN / UNKNOWN
- Last deploy: date + commit
- Last GitHub Actions result: success/failure
- Issues found (if any)
