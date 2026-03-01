---
name: setup
description: Guide authentication setup for Google Calendar and Microsoft 365 calendar access. Use when user says "setup calendar", "configure calendar", "connect calendar", "calendar auth", "calendar login", or wants to connect their calendar to Claude Code.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Calendar Access Setup

## Critical Rules

- **Never store credentials in the project directory** — all auth is external (gcalcli OAuth, Azure CLI login)
- **Never attempt to authenticate on behalf of the user** — guide them through the steps, let them run auth commands
- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`

## Context Files

Read these files before starting:

- `skills/shared/references/cross-cutting.md` — provider detection, error handling
- `skills/shared/references/providers.md` — CLI commands and response formats
- `skills/setup/references/auth-guide.md` — step-by-step auth instructions for both providers

## Workflow

### 1. Detect Current State

Check what's already installed and configured:

```bash
# Check gcalcli
command -v gcalcli && gcalcli list 2>&1

# Check Azure CLI
command -v az && az account show 2>&1

# Check for existing config
cat ~/.config/calendar-access/config.json 2>/dev/null
```

Report findings to the user:
- Which tools are installed
- Which are authenticated
- Which need setup

### 2. Ask User Which Providers to Configure

If neither is set up, ask which provider(s) they want:
- Google Calendar (requires gcalcli + Google Cloud project)
- Microsoft 365 (requires Azure CLI + Entra ID app registration)
- Both

### 3. Guide Authentication

Follow the step-by-step instructions from `skills/setup/references/auth-guide.md` for each selected provider. Present each step clearly and wait for the user to complete it before proceeding.

**For Google Calendar**:
1. Verify gcalcli is installed (or help install it)
2. Guide through Google Cloud project + Calendar API + OAuth credentials
3. Have user run `gcalcli --client-id=... list` to authenticate
4. Verify with `gcalcli list`

**For Microsoft 365**:
1. Verify Azure CLI is installed (or help install it)
2. Have user run `az login --allow-no-subscriptions`
3. Guide through app registration with `Calendars.Read` permission
4. Store client ID in `~/.config/calendar-access/config.json`
5. Verify with token acquisition and test API call

### 4. Verify Setup

Run verification commands for each configured provider:

```bash
# Google
gcalcli list

# Microsoft
TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $TOKEN" "https://graph.microsoft.com/v1.0/me/calendars" | python3 -c "import sys,json; cals=json.load(sys.stdin).get('value',[]); [print(f'  {c[\"name\"]}') for c in cals]"
```

### 5. Report

Summarize what was configured:
- Which providers are now active
- Calendar names visible from each provider
- Remind user they can use `/calendar-access:today` to see today's events

## Troubleshooting

Refer to the troubleshooting tables in `skills/setup/references/auth-guide.md` for provider-specific issues.

**Common issues**:
- Microsoft 403: App registration missing `Calendars.Read` — the Azure CLI's built-in app does NOT have this scope
- Google "Access blocked": User needs to add themselves as a test user in OAuth consent screen
- Azure "no subscriptions": Use `az login --allow-no-subscriptions` — an Azure subscription is NOT required for Graph API access
