---
name: next-week
description: Show calendar events for the next 7 days. Use when user says "next week's calendar", "upcoming week", "this week's meetings", "what's coming up this week", "weekly schedule", or wants to see the next 7 days of events.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Next Week's Calendar

Shortcut for viewing the next 7 days of events.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Read-only** — never create, modify, or delete events

## Context Files

- `skills/shared/references/cross-cutting.md` — provider detection, output format, error handling
- `skills/shared/references/providers.md` — CLI commands and response parsing

## Workflow

### 1. Calculate Date Range

```bash
START=$(date +%Y-%m-%d)
END=$(date -v+7d +%Y-%m-%d 2>/dev/null || date -d '+7 days' +%Y-%m-%d)
```

### 2. Detect Providers and Fetch Events

Follow provider detection from cross-cutting.md, then fetch events for the next 7 days using commands from providers.md.

**Google**: `gcalcli agenda "$START" "$END" --tsv --details location --nocolor`

**Microsoft**: Use `calendarView` with `startDateTime=${START}T00:00:00Z` and `endDateTime=${END}T00:00:00Z`

### 3. Format Output

Use the standard markdown table format from cross-cutting.md. Group events by day — one `## Calendar — Day` header per day. Skip days with no events.
