# Calendar Integration

This reference covers calendar service access, event normalization, and daily note insertion for vault skills that sync calendar events into Obsidian daily notes.

---

## Google Calendar via gcalcli

### OAuth2 Setup

`gcalcli` uses OAuth2 for authentication. Initial setup:

1. Install: `pip install gcalcli` or `brew install gcalcli`
2. First run triggers browser-based OAuth2 flow — user grants read access to Google Calendar
3. Credentials are stored in `~/.gcalcli_oauth` (do not commit this file)

### Calendar Discovery

```bash
# List all available calendars
gcalcli list
```

Output includes calendar name and access level. Use calendar names to filter events.

### Fetching Events

```bash
# Agenda for a specific date range (human-readable)
gcalcli agenda "2026-03-01" "2026-03-02" --details all

# JSON output for programmatic parsing
gcalcli agenda "2026-03-01" "2026-03-02" --tsv

# Filter by specific calendar
gcalcli --calendar "Work" agenda "2026-03-01" "2026-03-02" --details all
```

TSV output columns: start date, start time, end date, end time, title, location, description.

---

## Microsoft 365 via Azure CLI

### Authentication

```bash
# Interactive login (browser-based)
az login

# Verify access to Graph API
az account show
```

### Fetching Events

```bash
# Get calendar events for a date range
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/me/calendar/events" \
  --url-parameters \
    "\$filter=start/dateTime ge '2026-03-01T00:00:00' and end/dateTime le '2026-03-02T00:00:00'" \
    "\$select=subject,start,end,location,bodyPreview" \
    "\$orderby=start/dateTime"

# List available calendars
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/me/calendars" \
  --query "value[].{name:name, id:id}"

# Get events from a specific calendar
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/me/calendars/{calendar-id}/events" \
  --url-parameters \
    "\$filter=start/dateTime ge '2026-03-01T00:00:00' and end/dateTime le '2026-03-02T00:00:00'" \
    "\$select=subject,start,end,location,bodyPreview" \
    "\$orderby=start/dateTime"
```

Response is JSON with `value[]` array containing event objects. Key fields: `subject`, `start.dateTime`, `end.dateTime`, `location.displayName`, `bodyPreview`.

---

## Event Normalization

Regardless of source (Google Calendar or Microsoft 365), events should be normalized to a common structure before insertion into daily notes:

| Field | Source: gcalcli | Source: Azure CLI |
|-------|-----------------|-------------------|
| Start time | TSV column 1-2 (date + time) | `start.dateTime` (ISO 8601) |
| End time | TSV column 3-4 (date + time) | `end.dateTime` (ISO 8601) |
| Title | TSV column 5 | `subject` |
| Location | TSV column 6 | `location.displayName` |
| Description | TSV column 7 | `bodyPreview` |

Normalize all times to the vault's local timezone. Format times as `HH:MM` (24-hour) for consistency.

---

## Daily Note Insertion

### Finding the Right Daily Note

Obsidian vaults configure daily note paths through the Daily Notes core plugin or the Periodic Notes community plugin. Common patterns:

| Plugin | Config Location | Path Pattern |
|--------|----------------|--------------|
| Daily Notes (core) | `.obsidian/daily-notes.json` | `folder` + `format` fields |
| Periodic Notes | `.obsidian/plugins/periodic-notes/data.json` | `daily.folder` + `daily.format` fields |

The date format uses Moment.js tokens (e.g., `YYYY-MM-DD`, `YYYY/MM/MMMM/YYYY-MM-DD`). Convert the target date to the configured format to find or create the daily note file.

**Fallback detection**: If no plugin config is found, scan for files matching common patterns:
- `YYYY-MM-DD.md` in vault root
- `Daily Notes/YYYY-MM-DD.md`
- `Journal/YYYY-MM-DD.md`
- `YYYY/MM-MMMM/YYYY-MM-DD.md`

### Schedule Section Format

Insert events as a schedule section in the daily note. Events are sorted by start time.

```markdown
## Schedule

- **08:00 - 08:30** — Team standup (Zoom)
- **09:00 - 10:00** — Project review
  - Conference Room A
  - Review Q1 metrics and discuss roadmap
- **12:00 - 13:00** — Lunch with Sarah
  - Downtown Cafe
- **14:00 - 15:30** — Sprint planning (Teams)
- **16:00 - 16:30** — 1:1 with Manager

```

**Format rules**:
- Each event is a list item with bold time range and em-dash separator
- Time range: `HH:MM - HH:MM` (24-hour format)
- Location (if present) as indented sub-item
- Description (if present, non-empty) as indented sub-item below location
- All-day events listed at the top with `All day` instead of a time range
- Events sorted chronologically by start time

### Insertion Strategy

1. If the daily note already has a `## Schedule` section, replace its contents (preserve the heading)
2. If the daily note exists but has no schedule section, insert `## Schedule` after the frontmatter block (or after the first heading if no frontmatter)
3. If the daily note does not exist, create it using the vault's daily note template (if configured) and insert the schedule section
4. Never overwrite non-schedule content in the daily note
