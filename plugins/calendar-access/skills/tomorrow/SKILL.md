---
name: tomorrow
description: Show tomorrow's calendar events. Use when user says "tomorrow's calendar", "what's tomorrow", "meetings tomorrow", "tomorrow's schedule", "what do I have tomorrow", or wants to see tomorrow's events.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Tomorrow's Calendar

Shortcut for viewing tomorrow's events.

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Read-only** — never create, modify, or delete events

## Context Files

- `skills/shared/references/cross-cutting.md` — provider detection, output format, error handling
- `skills/shared/references/providers.md` — CLI commands and response parsing

## Workflow

### 1. Calculate Date Range

```bash
START=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d '+1 day' +%Y-%m-%d)
END=$(date -v+2d +%Y-%m-%d 2>/dev/null || date -d '+2 days' +%Y-%m-%d)
```

### 2. Detect Providers and Fetch Events

Follow provider detection from cross-cutting.md, then fetch events for tomorrow using commands from providers.md.

**Google**: `gcalcli agenda "$START" "$END" --tsv --details location --nocolor`

**Microsoft**: Use `calendarView` with `startDateTime=${START}T00:00:00Z` and `endDateTime=${END}T00:00:00Z`

### 3. Format Output

Use the standard markdown table format from cross-cutting.md with a single day header for tomorrow.
