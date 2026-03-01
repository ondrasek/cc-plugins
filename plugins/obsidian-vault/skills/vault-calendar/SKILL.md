---
name: vault-calendar
description: Pull events from Google Calendar or Microsoft 365 into Obsidian daily notes. Use when user says "import calendar", "add today's events", "calendar to daily note", "sync calendar", or wants to populate daily notes with scheduled events.
metadata:
  version: 0.1.0
  author: Ondrej (Ondra) Krajicek, me@ondrejkrajicek.com
---

# Vault Calendar

## Critical Rules

- **Never store credentials in the vault** — calendar auth is handled externally by the user (OAuth2 for Google, `az login` for Microsoft)
- **Always confirm with user before writing to daily notes** — show the formatted events and target file path before inserting
- **Adapt format to vault's daily note template structure** — detect existing sections and insert schedule content in the appropriate location

## Context Files

Read these files before starting:

- `skills/vault-calendar/references/calendar-providers.md` — provider detection, CLI commands, response parsing
- `skills/vault-calendar/references/daily-note-format.md` — event formatting, daily note detection, section insertion rules

## Workflow

### 1. Detect Calendar Provider

Check which calendar CLI tools are available:
- Google Calendar: `command -v gcalcli`
- Microsoft 365: `command -v az` and `az account show`

If neither is available, report which tools to install and how to authenticate. Do not proceed without a working provider.

### 2. Detect Daily Notes Configuration

Read vault configuration to find daily note settings:
- Check `.obsidian/daily-notes.json` for folder, format, and template settings
- Check `.obsidian/community-plugins.json` for Periodic Notes plugin
- If Periodic Notes is active, check `.obsidian/plugins/periodic-notes/data.json` instead
- Fall back to defaults: root folder, `YYYY-MM-DD` format, no template

### 3. Fetch Events for Target Date

Fetch calendar events for the specified date (default: today):
- Use provider-specific commands from `calendar-providers.md`
- Parse the response into a structured list of events
- Handle edge cases: all-day events, multi-day events, no events found

### 4. Format Events as Markdown

Format events following the patterns in `daily-note-format.md`:
- Adapt to the vault's daily note template if one exists
- Use 24h time format by default, adapt to vault convention if detected
- Include location and description where available

### 5. Insert/Update Schedule Section in Daily Note

Construct the daily note path from the detected configuration:
- If the daily note exists, find the schedule section and replace it (or insert after frontmatter)
- If the daily note does not exist, create it from the vault template or create a minimal note
- Preserve all other content in the daily note

### 6. Report

Tell the user what was added: number of events, target file path, any events that were skipped or problematic.

## Troubleshooting

**gcalcli not installed**: Suggest `pip install gcalcli` or `brew install gcalcli`. User must run `gcalcli init` to authenticate.

**Azure CLI not installed**: Suggest `brew install azure-cli` or platform-appropriate install. User must run `az login` to authenticate.

**Not authenticated**: Do not attempt to authenticate on behalf of the user. Instruct them to run the auth command externally and retry.

**No events found**: Report "no events scheduled for [date]" — this is not an error.

**Daily note template not found**: Create a minimal daily note with frontmatter (date, created timestamp) and the schedule section.
