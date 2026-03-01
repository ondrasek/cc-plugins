# calendar-access

Read-only calendar access for Claude Code via CLI tools. Supports Google Calendar (gcalcli) and Microsoft 365 (Azure CLI + Graph API).

## Features

- **View events** for any date or date range
- **Search** by keyword, attendee, or calendar name
- **List calendars** from all configured providers
- **Quick shortcuts** for today, tomorrow, next/last week, next/last month
- **SessionStart hook** shows upcoming events when you start a session
- **Multi-provider** — use Google and Microsoft together, results merged chronologically

## Providers

| Provider | CLI Tool | Auth Method |
|----------|----------|-------------|
| Google Calendar | [gcalcli](https://github.com/insanum/gcalcli) | OAuth2 (desktop app credentials) |
| Microsoft 365 | [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) + Graph API | Entra ID app registration with `Calendars.Read` |

**Important**: Azure CLI's built-in app registration does NOT have `Calendars.Read` scope. You must create a custom Entra ID app registration. The setup skill guides you through this.

## Installation

```bash
/plugin install calendar-access@cc-plugins
```

Or for local development:

```bash
claude --plugin-dir /path/to/cc-plugins/plugins/calendar-access
```

## Setup

Run the setup skill to configure authentication:

```
/calendar-access:setup
```

This detects installed tools and guides you through authentication for each provider.

## Skills

| Skill | Description |
|-------|-------------|
| `setup` | Guide authentication for Google and/or Microsoft |
| `view` | Show events for a specific date or date range |
| `search` | Find events by keyword, attendee, or calendar |
| `list-calendars` | List available calendars from all providers |
| `today` | Today's events |
| `tomorrow` | Tomorrow's events |
| `next-week` | Next 7 days |
| `next-month` | Next 30 days |
| `last-week` | Past 7 days |
| `last-month` | Past 30 days |

## Output Format

Events are displayed as markdown tables grouped by day:

```markdown
## Calendar — Monday, March 2, 2026

| Time | Event | Location |
|------|-------|----------|
| All day | Company Holiday | |
| 09:00–09:30 | Team standup | Zoom |
| 14:00–15:30 | Sprint planning | Teams |
```

## Hook

**SessionStart** — shows up to 4 upcoming events for the rest of today. Non-blocking, silent if no provider is configured.

## Config Storage

- Microsoft client ID: `~/.config/calendar-access/config.json`
- Google credentials: `~/.gcalcli_oauth` (managed by gcalcli)
- Credentials are never stored in the project directory
