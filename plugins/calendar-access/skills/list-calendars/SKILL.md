---
name: list-calendars
description: List all available calendars from configured providers. Use when user says "list my calendars", "which calendars do I have", "show calendars", "what calendars are available", or wants to see which calendars they can access.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# List Calendars

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Read-only** — never create, modify, or delete calendars

## Context Files

Read these files before starting:

- `skills/shared/references/cross-cutting.md` — provider detection, error handling
- `skills/shared/references/providers.md` — CLI commands for listing calendars

## Workflow

### 1. Detect Providers

Follow provider detection from cross-cutting.md. Stop if no provider is available.

### 2. List Calendars

**Google Calendar**:
```bash
gcalcli list
```

**Microsoft 365**:
```bash
TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendars?\$select=name,color,isDefaultCalendar,canEdit"
```

### 3. Format Output

Present as a table grouped by provider:

```markdown
## Calendars

### Google Calendar
| Calendar | Access |
|----------|--------|
| Personal | owner |
| Work | reader |
| Holidays in US | reader |

### Microsoft 365
| Calendar | Default | Color |
|----------|---------|-------|
| Calendar | Yes | Blue |
| Birthdays | No | Purple |
```

If only one provider is configured, omit the provider header grouping.
