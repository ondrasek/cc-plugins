---
name: search
description: Search calendar events by keyword, attendee, or calendar name. Use when user says "find meeting with Alice", "when is the next standup", "meetings about project X", "search calendar for budget", or wants to find specific events across their calendar.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Search Calendar

## Critical Rules

- **Read cross-cutting behaviors first**: `skills/shared/references/cross-cutting.md`
- **Read-only** — never create, modify, or delete events
- **Search broadly, then filter** — cast a wide net with the search query, then filter results for relevance

## Context Files

Read these files before starting:

- `skills/shared/references/cross-cutting.md` — provider detection, output format, error handling
- `skills/shared/references/providers.md` — CLI commands and search syntax

## Workflow

### 1. Extract Search Parameters

From the user's request, determine:
- **Keyword(s)**: the subject/title to search for
- **Attendee**: if searching for meetings with a specific person
- **Calendar**: if searching a specific calendar
- **Date range**: if the user specifies a time window (default: next 30 days)

### 2. Detect Providers

Follow provider detection from cross-cutting.md. Stop if no provider is available.

### 3. Search Events

**Google Calendar**:
```bash
# Keyword search (searches upcoming events by default)
gcalcli search "KEYWORD" --tsv --details location --nocolor

# With date range
gcalcli search "KEYWORD" "START_DATE" "END_DATE" --tsv --details location --nocolor
```

**Microsoft 365**:
```bash
TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)

# Keyword search
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/events?\$search=\"KEYWORD\"&\$select=subject,start,end,location,isAllDay,attendees,organizer&\$top=20&\$orderby=start/dateTime"
```

For attendee searches on Microsoft, examine the `attendees` and `organizer` fields in the results.

### 4. Format Output

Use the markdown table format from cross-cutting.md. Group results by day.

If searching for an attendee, include an Attendees column:

```markdown
## Search Results — "standup"

| Time | Event | Location | Calendar |
|------|-------|----------|----------|
| 09:00–09:30 | Daily standup | Zoom | Work |
| 09:00–09:30 | Daily standup | Zoom | Work |
```

Report the total number of matches found.
