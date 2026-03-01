#!/bin/bash
# SessionStart hook: show up to 4 upcoming events for the rest of today
# Non-blocking — always exits 0. Silent if no provider configured.

NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
TODAY=$(date +"%Y-%m-%d" 2>/dev/null)
END_OF_DAY="${TODAY}T23:59:59"
NOW_EPOCH=$(date +%s 2>/dev/null)

EVENTS=()

# ---------- Google Calendar (gcalcli) ----------
if command -v gcalcli >/dev/null 2>&1; then
    # gcalcli agenda outputs events from now to end of day
    GCAL_OUTPUT=$(gcalcli agenda "$TODAY" "$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d '+1 day' +%Y-%m-%d 2>/dev/null)" \
        --tsv --details location --nocolor 2>/dev/null)
    if [[ $? -eq 0 && -n "$GCAL_OUTPUT" ]]; then
        while IFS=$'\t' read -r start_date start_time end_date end_time event_title location; do
            [[ -z "$event_title" ]] && continue
            # Skip events that have already ended
            if [[ -n "$end_time" && "$end_time" != " " ]]; then
                END_TS="${end_date} ${end_time}"
                END_EPOCH=$(date -j -f "%Y-%m-%d %H:%M" "$END_TS" +%s 2>/dev/null || date -d "$END_TS" +%s 2>/dev/null)
                if [[ -n "$END_EPOCH" && "$END_EPOCH" -lt "$NOW_EPOCH" ]]; then
                    continue
                fi
            fi
            if [[ -n "$start_time" && "$start_time" != " " ]]; then
                TIME_RANGE="${start_time}–${end_time}"
            else
                TIME_RANGE="All day"
            fi
            LOC_PART=""
            if [[ -n "$location" && "$location" != " " ]]; then
                LOC_PART=" ($location)"
            fi
            EVENTS+=("  ${TIME_RANGE}  ${event_title}${LOC_PART}")
        done <<< "$GCAL_OUTPUT"
    fi
fi

# ---------- Microsoft 365 (Azure CLI + Graph API) ----------
CONFIG_FILE="${HOME}/.config/calendar-access/config.json"
if command -v az >/dev/null 2>&1 && [[ -f "$CONFIG_FILE" ]]; then
    # Check if authenticated
    az account show >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv 2>/dev/null)
        if [[ -n "$TOKEN" ]]; then
            GRAPH_URL="https://graph.microsoft.com/v1.0/me/calendarView?startDateTime=${NOW_ISO}&endDateTime=${END_OF_DAY}Z&\$orderby=start/dateTime&\$top=10&\$select=subject,start,end,location,isAllDay"
            GRAPH_JSON=$(curl -s -H "Authorization: Bearer $TOKEN" "$GRAPH_URL" 2>/dev/null)
            if [[ -n "$GRAPH_JSON" ]] && echo "$GRAPH_JSON" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
                PARSED=$(echo "$GRAPH_JSON" | python3 -c "
import sys, json
from datetime import datetime
data = json.load(sys.stdin)
for e in data.get('value', []):
    subj = e.get('subject', '(No title)')
    loc = e.get('location', {}).get('displayName', '')
    is_all_day = e.get('isAllDay', False)
    if is_all_day:
        time_range = 'All day'
    else:
        s = datetime.fromisoformat(e['start']['dateTime'].rstrip('Z')).strftime('%H:%M')
        en = datetime.fromisoformat(e['end']['dateTime'].rstrip('Z')).strftime('%H:%M')
        time_range = f'{s}\u2013{en}'
    loc_part = f' ({loc})' if loc else ''
    print(f'  {time_range}  {subj}{loc_part}')
" 2>/dev/null)
                while IFS= read -r line; do
                    [[ -n "$line" ]] && EVENTS+=("$line")
                done <<< "$PARSED"
            fi
        fi
    fi
fi

# ---------- Output ----------
if [[ ${#EVENTS[@]} -eq 0 ]]; then
    exit 0
fi

# Limit to 4 events
TOTAL=${#EVENTS[@]}
DISPLAY=4
if [[ $TOTAL -lt $DISPLAY ]]; then
    DISPLAY=$TOTAL
fi

echo "Today's calendar (${TOTAL} upcoming):" >&2
for ((i=0; i<DISPLAY; i++)); do
    echo "${EVENTS[$i]}" >&2
done
if [[ $TOTAL -gt 4 ]]; then
    echo "  ... and $((TOTAL - 4)) more" >&2
fi

exit 0
