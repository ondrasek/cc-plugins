# Daily Note Format

This reference covers how to format calendar events into daily note markdown and how to detect and write to the correct daily note file.

---

## Event Format

### Standard Schedule Section

```markdown
## Schedule

- **09:00-10:00** Meeting Title -- Conference Room A
- **10:30-11:00** Another Event
  - Notes: Brief description from calendar
- **14:00-15:30** Workshop on Topic -- Building 3, Room 201
  - Notes: Bring laptop and project files
- **All day** Company Holiday
```

### Formatting Rules

| Element | Format | Notes |
|---------|--------|-------|
| Time range | `**HH:MM-HH:MM**` | 24h format by default |
| Title | Plain text after time | Event subject/title |
| Location | ` -- Location` after title | Only if location is non-empty |
| Description | Indented `- Notes: ...` | Only if description is non-empty; truncate at 200 chars |
| All-day events | `**All day**` instead of time | Listed at the end of the schedule |

### Time Format

- Default: 24-hour format (`09:00`, `14:30`)
- If the vault uses 12h format in existing notes (detected by scanning), adapt: `9:00 AM`, `2:30 PM`
- To detect vault convention: search existing daily notes for time patterns like `\d{1,2}:\d{2}\s?[AaPp][Mm]`

---

## Daily Note Detection

### Configuration Sources (checked in order)

1. **Periodic Notes plugin** (if installed):
   - Check `.obsidian/community-plugins.json` for `"periodic-notes"`
   - Read `.obsidian/plugins/periodic-notes/data.json`
   - Daily note settings in `daily.folder`, `daily.format`, `daily.template`

2. **Daily Notes core plugin**:
   - Read `.obsidian/daily-notes.json`
   - Fields: `folder`, `format`, `template`

3. **Defaults** (if no configuration found):
   - Folder: vault root (`""`)
   - Format: `YYYY-MM-DD`
   - Template: none

### Path Construction

```
{vault_root}/{folder}/{date_formatted_with_format}.md
```

Examples:
- Config: `folder: "Daily Notes"`, format: `YYYY-MM-DD` -> `Daily Notes/2025-01-15.md`
- Config: `folder: "journal/daily"`, format: `YYYY/MM/YYYY-MM-DD` -> `journal/daily/2025/01/2025-01-15.md`
- Default: `2025-01-15.md` (vault root)

### Date Format Tokens

Obsidian uses Moment.js format tokens:

| Token | Meaning | Example |
|-------|---------|---------|
| `YYYY` | 4-digit year | 2025 |
| `YY` | 2-digit year | 25 |
| `MM` | 2-digit month | 01 |
| `M` | Month (no padding) | 1 |
| `DD` | 2-digit day | 15 |
| `D` | Day (no padding) | 15 |
| `ddd` | Short weekday | Wed |
| `dddd` | Full weekday | Wednesday |

---

## Section Insertion

### If daily note exists

1. **Has existing Schedule/Calendar section**: Find the heading (`## Schedule`, `## Calendar`, `## Events`, or similar) and replace the content up to the next same-level heading. Preserve the heading text the vault uses.

2. **Has no schedule section**: Insert after frontmatter (after the closing `---`). If no frontmatter, insert at the top of the file.

3. **Has a template placeholder**: If the daily note template contains a placeholder like `{{schedule}}`, `<!-- schedule -->`, or `%% schedule %%`, replace the placeholder with the formatted schedule.

### If daily note does not exist

1. **Template configured**: Read the template file and create the daily note from it. Then insert the schedule section using the rules above.

2. **No template**: Create a minimal daily note:

```markdown
---
date: YYYY-MM-DD
created: YYYY-MM-DDTHH:MM:SS
---

## Schedule

- **09:00-10:00** First Event
...
```

### Content Preservation

- Never delete or modify content outside the schedule section
- If the user has manually added items to the schedule section, warn before replacing
- When updating (re-running for the same day), replace the entire schedule section with fresh data

---

## Adaptation

### Periodic Notes Plugin

If the vault uses Periodic Notes instead of the core Daily Notes plugin:
- Check `.obsidian/plugins/periodic-notes/data.json` for daily note configuration
- The settings structure differs: `daily.folder`, `daily.format`, `daily.template` (nested under `daily`)
- Weekly/monthly/quarterly notes are separate configurations — this skill only targets daily notes

### Template-Aware Insertion

If the daily note template has a specific section or placeholder for schedule content:
- Scan the template for headings containing "schedule", "calendar", "events", or "agenda"
- Scan for placeholder patterns: `{{schedule}}`, `<!-- schedule -->`, `%% schedule %%`
- Insert at the detected location rather than the default position

### Time Zone

- Events from calendar providers may be in UTC
- Convert to the system's local timezone before formatting
- Use `date +%Z` to detect the system timezone if needed
