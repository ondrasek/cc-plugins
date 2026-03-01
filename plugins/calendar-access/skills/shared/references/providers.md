---
type: reference
used_by: setup, view, search, list-calendars, today, tomorrow, next-week, next-month, last-week, last-month
description: Provider-specific CLI commands, response parsing, and field mapping for Google Calendar and Microsoft 365.
---

# Calendar Providers

## 1. Google Calendar (gcalcli)

### Detection

```bash
command -v gcalcli >/dev/null 2>&1
```

### Auth Check

```bash
gcalcli list >/dev/null 2>&1
```

If this fails with an auth error, the user needs to run `gcalcli init` or re-authenticate.

### Fetch Events (agenda)

```bash
# Events for a date range
gcalcli agenda "START_DATE" "END_DATE" --tsv --details location --details description --nocolor

# Example: today's events
gcalcli agenda "2026-03-01" "2026-03-02" --tsv --details location --nocolor
```

**TSV columns**: `start_date`, `start_time`, `end_date`, `end_time`, `title`, `location` (when `--details location` is used)

**All-day events**: `start_time` and `end_time` are empty.

### Search Events

```bash
# Keyword search
gcalcli search "KEYWORD" --tsv --details location --nocolor

# Search within date range
gcalcli search "KEYWORD" "START_DATE" "END_DATE" --tsv --details location --nocolor
```

### List Calendars

```bash
gcalcli list
```

Output format: `access_role  calendar_name` (one per line). Parse by splitting on first whitespace.

### Specifying a Calendar

```bash
gcalcli agenda --calendar "Calendar Name" "START_DATE" "END_DATE" --tsv --nocolor
```

---

## 2. Microsoft 365 (Azure CLI + Graph API)

### Detection

```bash
command -v az >/dev/null 2>&1
```

### Auth Check

```bash
az account show >/dev/null 2>&1
```

### Token Acquisition

```bash
TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
```

If this fails, the user needs to run `az login --allow-no-subscriptions`.

### Fetch Events (calendarView)

Uses `calendarView` endpoint — this automatically expands recurring events.

```bash
START="2026-03-01T00:00:00Z"
END="2026-03-02T00:00:00Z"

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendarView?\$orderby=start/dateTime&startDateTime=${START}&endDateTime=${END}&\$select=subject,start,end,location,isAllDay,bodyPreview"
```

**JSON response structure**:
```json
{
  "value": [
    {
      "subject": "Team standup",
      "start": { "dateTime": "2026-03-01T09:00:00.0000000", "timeZone": "UTC" },
      "end": { "dateTime": "2026-03-01T09:30:00.0000000", "timeZone": "UTC" },
      "location": { "displayName": "Zoom" },
      "isAllDay": false,
      "bodyPreview": "Weekly sync..."
    }
  ]
}
```

### Search Events

Use `$filter` or `$search` on the events endpoint:

```bash
# Search by subject keyword
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/events?\$search=\"KEYWORD\"&\$select=subject,start,end,location,isAllDay&\$top=20&\$orderby=start/dateTime"
```

Note: `$search` requires the `Prefer: "outlook.body-content-type=text"` header for best results.

```bash
# Filter by organizer or attendee
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Prefer: outlook.body-content-type=text" \
  "https://graph.microsoft.com/v1.0/me/events?\$search=\"KEYWORD\"&\$select=subject,start,end,location,isAllDay,attendees,organizer&\$top=20"
```

### List Calendars

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendars?\$select=name,color,isDefaultCalendar,canEdit"
```

### Fetch Events from Specific Calendar

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://graph.microsoft.com/v1.0/me/calendars/{CALENDAR_ID}/calendarView?startDateTime=${START}&endDateTime=${END}&\$orderby=start/dateTime&\$select=subject,start,end,location,isAllDay"
```

---

## 3. Event Field Mapping

Normalize events from both providers into a common structure for output:

| Common Field | Google (gcalcli TSV) | Microsoft (Graph JSON) |
|-------------|---------------------|----------------------|
| title | Column 5 (`title`) | `subject` |
| start_date | Column 1 (`start_date`) | `start.dateTime` (parse date) |
| start_time | Column 2 (`start_time`) | `start.dateTime` (parse time) |
| end_date | Column 3 (`end_date`) | `end.dateTime` (parse date) |
| end_time | Column 4 (`end_time`) | `end.dateTime` (parse time) |
| location | Column 6 (`location`) | `location.displayName` |
| is_all_day | Empty start_time/end_time | `isAllDay` boolean |
| description | `--details description` column | `bodyPreview` |

### Timezone Handling

- **Google**: gcalcli outputs times in the user's local timezone by default
- **Microsoft**: Graph API returns times in UTC (or the timezone specified in the `Prefer: outlook.timezone` header). Convert to local:

```bash
# Request events in local timezone
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Prefer: outlook.timezone=\"$(date +%Z)\"" \
  "https://graph.microsoft.com/v1.0/me/calendarView?..."
```

Or convert UTC to local in Python:

```python
from datetime import datetime, timezone
import time

utc_dt = datetime.fromisoformat(dt_string.rstrip('Z')).replace(tzinfo=timezone.utc)
local_dt = utc_dt.astimezone()
```
