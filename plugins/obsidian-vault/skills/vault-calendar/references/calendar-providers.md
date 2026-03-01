# Calendar Providers

This reference covers how to detect, authenticate, and fetch events from supported calendar providers.

---

## Google Calendar (gcalcli)

### Detection

```bash
command -v gcalcli
```

If not installed, suggest: `pip install gcalcli` or `brew install gcalcli`.

### Authentication

Auth is handled externally by the user. gcalcli uses OAuth2:

```bash
gcalcli init
```

This opens a browser for Google account authorization. The plugin never initiates auth — instruct the user to do it.

### List Calendars

```bash
gcalcli list
```

Shows all available calendars (useful for filtering by calendar name).

### Fetch Events

```bash
gcalcli agenda "YYYY-MM-DD" "YYYY-MM-DD+1" --details all --tsv
```

Replace dates with the target range. For a single day, use start = target date, end = next day.

### TSV Output Fields

The `--tsv` flag produces tab-separated output with these columns:

| Field | Description |
|-------|-------------|
| start_date | Event start date (YYYY-MM-DD) |
| start_time | Event start time (HH:MM) or empty for all-day |
| end_date | Event end date (YYYY-MM-DD) |
| end_time | Event end time (HH:MM) or empty for all-day |
| title | Event title/subject |
| location | Event location (may be empty) |
| description | Event description/body (may be empty) |
| calendar | Calendar name |

### Edge Cases

- **All-day events**: start_time and end_time are empty. Format as "All day" in the schedule.
- **Multi-day events**: start_date and end_date differ. Show only the portion relevant to the target date.
- **No events**: gcalcli returns empty output. This is not an error.

---

## Microsoft 365 (Azure CLI)

### Detection

```bash
command -v az && az account show 2>/dev/null
```

Both conditions must succeed. `az` must be installed AND the user must be logged in.

If not installed, suggest: `brew install azure-cli` or platform-appropriate install.

### Authentication

Auth is handled externally by the user:

```bash
az login
```

This opens a browser for Microsoft account authorization. The plugin never initiates auth — instruct the user to do it.

### Fetch Events

```bash
az rest --method GET \
  --url "https://graph.microsoft.com/v1.0/me/calendarView" \
  --url-parameters \
    "startDateTime=YYYY-MM-DDT00:00:00Z" \
    "endDateTime=YYYY-MM-DDT23:59:59Z" \
    "\$select=subject,start,end,location,bodyPreview" \
    "\$orderby=start/dateTime"
```

Replace `YYYY-MM-DD` with the target date. The `$` in query parameters must be escaped with `\$`.

### JSON Response Structure

```json
{
  "value": [
    {
      "subject": "Meeting Title",
      "start": {
        "dateTime": "2025-01-15T09:00:00.0000000",
        "timeZone": "UTC"
      },
      "end": {
        "dateTime": "2025-01-15T10:00:00.0000000",
        "timeZone": "UTC"
      },
      "location": {
        "displayName": "Conference Room A"
      },
      "bodyPreview": "Agenda: discuss Q1 goals..."
    }
  ]
}
```

### Parsing Notes

- Times are in UTC — convert to local timezone using the system timezone
- `location.displayName` may be empty string or null
- `bodyPreview` is a plain-text preview of the event body (max ~255 chars)
- All-day events have `isAllDay: true` (if `$select` includes it)

### Edge Cases

- **All-day events**: `start.dateTime` and `end.dateTime` span full days. Check time portion or include `isAllDay` in `$select`.
- **Recurring events**: CalendarView automatically expands recurrences — each occurrence appears as a separate event.
- **No events**: `value` array is empty. This is not an error.

---

## Error Handling

| Scenario | Detection | Action |
|----------|-----------|--------|
| Tool not installed | `command -v` fails | Suggest installation command for the platform |
| Not authenticated | gcalcli errors with auth message / `az account show` fails | Instruct user to authenticate externally, then retry |
| No events found | Empty output / empty `value` array | Report "no events scheduled for [date]" — not an error |
| Network error | Non-zero exit code with connection error | Report the error, suggest checking network connectivity |
| Permission denied | API returns 403 | Suggest re-authenticating with calendar read permissions |
