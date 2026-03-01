---
name: next-month
description: Show calendar events for the next 30 days. Use when user says "next month's calendar", "upcoming month", "what's coming up this month", "monthly schedule", or wants to see the next 30 days of events.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Next Month's Calendar

Shortcut for viewing the next 30 days of events.

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
END=$(date -v+30d +%Y-%m-%d 2>/dev/null || date -d '+30 days' +%Y-%m-%d)
```

### 2. Detect Providers and Fetch Events

Follow provider detection from cross-cutting.md, then fetch events for the next 30 days using commands from providers.md.

**Google**: `gcalcli agenda "$START" "$END" --tsv --details location --nocolor`

**Microsoft**: Use `calendarView` with `startDateTime=${START}T00:00:00Z` and `endDateTime=${END}T00:00:00Z`

### 3. Format Output

Use the standard markdown table format from cross-cutting.md. Group events by day — one `## Calendar — Day` header per day. Skip days with no events.

For 30-day views, consider summarizing days with many events (e.g., "5 events") and expanding on request.
