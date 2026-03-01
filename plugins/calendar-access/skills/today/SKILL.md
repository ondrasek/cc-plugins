---
name: today
description: Show today's calendar events. Use when user says "today's calendar", "today's meetings", "what's on today", "today's schedule", "what do I have today", or wants to see today's events.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Today's Calendar

Shortcut for viewing today's events.

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
END=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d '+1 day' +%Y-%m-%d)
```

### 2. Detect Providers and Fetch Events

Follow provider detection from cross-cutting.md, then fetch events for today using commands from providers.md.

**Google**: `gcalcli agenda "$START" "$END" --tsv --details location --nocolor`

**Microsoft**: Use `calendarView` with `startDateTime=${START}T00:00:00Z` and `endDateTime=${END}T00:00:00Z`

### 3. Format Output

Use the standard markdown table format from cross-cutting.md with a single day header for today.
