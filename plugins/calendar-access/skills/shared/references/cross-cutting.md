---
type: reference
used_by: setup, view, search, list-calendars, today, tomorrow, next-week, next-month, last-week, last-month
description: Cross-cutting behaviors that apply to ALL calendar-access skills. Read this before executing any skill.
---

# Cross-Cutting Behaviors

Every calendar-access skill MUST follow these behaviors. They are not optional.

## 1. Read-Only Guarantee

**NEVER create, modify, or delete calendar events.** This plugin is strictly read-only. If a user asks to create or modify events, explain that this plugin only provides read access and suggest they use their calendar application directly.

## 2. Provider Detection

Check which calendar providers are available before any operation:

```bash
# Google Calendar
command -v gcalcli >/dev/null 2>&1 && gcalcli list >/dev/null 2>&1

# Microsoft 365
command -v az >/dev/null 2>&1 && az account show >/dev/null 2>&1
```

**If neither provider is available**, tell the user to run `/calendar-access:setup` and stop.

**If a provider's CLI tool is installed but not authenticated**, report the specific auth issue and suggest `/calendar-access:setup`.

## 3. Multi-Provider Behavior

When both Google and Microsoft are configured:
- Fetch events from **both** providers
- **Merge results chronologically** by start time
- Label the source if events overlap or if the user asks which calendar an event is from
- De-duplication is NOT attempted — the same event may appear from different providers if the user has mirrored calendars

When only one provider is configured, use that provider silently without mentioning the other.

## 4. Time Handling

- **24-hour format** by default (e.g., `09:00`, `14:30`)
- **UTC to local**: Convert all UTC timestamps to the user's local timezone. Use the system timezone.
- **All-day events**: Display as "All day" in the Time column, sort them before timed events for that day
- **Multi-day events**: Show on each day they span, with a note like "(Day 2 of 3)"
- **Date arguments**: When the user specifies dates naturally (e.g., "next Tuesday", "March 5"), calculate the correct date. Use `date` command for date arithmetic.

## 5. Output Format

### Standard format (for skills that show events)

Use a markdown table grouped by day:

```markdown
## Calendar — Monday, March 2, 2026

| Time | Event | Location |
|------|-------|----------|
| All day | Company Holiday | |
| 09:00–09:30 | Team standup | Zoom |
| 14:00–15:30 | Sprint planning | Teams |
```

Rules:
- One `## Calendar — Day, Month Date, Year` header per day
- All-day events sort first within each day
- Timed events sort chronologically
- Empty Location column is fine — do not show "N/A" or "-"
- Use en-dash `–` between start and end times

### No events

When there are no events for the requested period:

```markdown
## Calendar — Monday, March 2, 2026

No events scheduled.
```

## 6. Error Handling

| Situation | Action |
|-----------|--------|
| CLI tool not installed | "gcalcli is not installed. Run `/calendar-access:setup` for installation and auth instructions." |
| Not authenticated | "Azure CLI is installed but not authenticated. Run `/calendar-access:setup` to configure." |
| Permission denied (403) | "Calendar access denied. Your app registration may be missing `Calendars.Read` permission. Run `/calendar-access:setup` to verify." |
| Network error | "Could not reach the calendar API. Check your internet connection." |
| No events found | Show the "No events scheduled" format above — this is not an error |

## 7. Provider CLI Commands Reference

For detailed CLI commands and response parsing, read `skills/shared/references/providers.md`.

## 8. Config Storage

- Microsoft app registration client ID: `~/.config/calendar-access/config.json`
- Google credentials: `~/.gcalcli_oauth` (managed by gcalcli)
- **Never store credentials in the project directory**
