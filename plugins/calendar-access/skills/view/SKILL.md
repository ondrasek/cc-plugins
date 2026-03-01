---
name: view
description: Show calendar events for a specific date or date range. Use when user says "show calendar", "events for March 5", "calendar for next Tuesday", "show me my schedule", "what meetings do I have on Friday", or wants to view events for any date or date range.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# View Calendar

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Read-only** — never create, modify, or delete events
- **Parse natural language dates** — "next Tuesday", "March 5", "this Friday" must be resolved to actual dates

## Context Files

Read these files before starting:

- `skills/shared/references/cross-cutting.md` — provider detection, output format, error handling
- `skills/shared/references/providers.md` — CLI commands and response parsing

## Workflow

### 1. Parse Date Range

Determine the date range from the user's request:
- Single date: "March 5" → start=2026-03-05, end=2026-03-06
- Date range: "March 5 to March 10" → start=2026-03-05, end=2026-03-11
- Relative: "next Tuesday" → calculate from today's date
- No date specified: default to today

Use `date` command for date arithmetic:
```bash
# Today
date +%Y-%m-%d

# Tomorrow
date -v+1d +%Y-%m-%d  # macOS
date -d '+1 day' +%Y-%m-%d  # Linux

# Next Tuesday (macOS)
date -v+tue +%Y-%m-%d
```

### 2. Detect Providers

Follow provider detection from cross-cutting.md. Stop if no provider is available.

### 3. Fetch Events

**Google Calendar**:
```bash
gcalcli agenda "START_DATE" "END_DATE" --tsv --details location --nocolor
```

**Microsoft 365**:
```bash
TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendarView?startDateTime=START_ISOZ&endDateTime=END_ISOZ&\$orderby=start/dateTime&\$select=subject,start,end,location,isAllDay"
```

### 4. Format Output

Use the markdown table format from cross-cutting.md. Group events by day if the range spans multiple days.

If both providers are configured, merge results chronologically.
