---
type: reference
used_by: setup
description: Step-by-step authentication guides for Google Calendar and Microsoft 365 providers.
---

# Authentication Guide

## 1. Google Calendar (gcalcli)

### Prerequisites

- Python 3 with pip
- A Google account with Calendar access

### Installation

```bash
# macOS
brew install gcalcli
# or
pip install gcalcli

# Linux
pip install gcalcli
```

### Authentication Steps

1. **Create a Google Cloud project** (if you don't have one):
   - Go to https://console.cloud.google.com/projectcreate
   - Name the project (e.g., "Calendar CLI")
   - Click Create

2. **Enable the Google Calendar API**:
   - Go to https://console.cloud.google.com/apis/library/calendar-json.googleapis.com
   - Select your project
   - Click Enable

3. **Create OAuth2 credentials**:
   - Go to https://console.cloud.google.com/apis/credentials
   - Click "Create Credentials" → "OAuth client ID"
   - If prompted, configure the OAuth consent screen first (External, fill in app name and email)
   - Application type: "Desktop app"
   - Name: "gcalcli"
   - Click Create
   - Copy the **Client ID** and **Client Secret**

4. **Authenticate gcalcli**:
   ```bash
   gcalcli --client-id="YOUR_CLIENT_ID" list
   ```
   This opens a browser window for OAuth consent. After granting access, credentials are stored in `~/.gcalcli_oauth`.

5. **Verify**:
   ```bash
   gcalcli list
   ```
   Should display your calendar names.

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "Access blocked: This app's request is invalid" | You need to add yourself as a test user in the OAuth consent screen |
| "Error: invalid_client" | Client ID or Secret is wrong. Re-check the credentials page |
| "HttpError 403" | Calendar API is not enabled. Enable it at the API library |
| Token expired | Run `gcalcli --client-id="YOUR_CLIENT_ID" list` again to re-authenticate |

---

## 2. Microsoft 365 (Azure CLI + Custom App Registration)

### Why a Custom App Registration?

The Azure CLI's built-in app registration does **not** include `Calendars.Read` scope. Running `az rest` against Graph calendar endpoints returns 403. You must create a custom Entra ID app registration with `Calendars.Read` delegated permission.

### Prerequisites

- Azure CLI installed (`az` command available)
- A Microsoft 365 account (work, school, or personal)
- Ability to create app registrations in Entra ID (Azure AD)

### Installation

```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Authentication Steps

1. **Sign in to Azure CLI**:
   ```bash
   az login --allow-no-subscriptions
   ```
   The `--allow-no-subscriptions` flag is needed if you don't have an Azure subscription (common for M365-only accounts).

2. **Create an App Registration** (CLI method):
   ```bash
   az ad app create \
     --display-name "Calendar CLI" \
     --public-client-redirect-uris "http://localhost" \
     --required-resource-accesses '[{
       "resourceAppId": "00000003-0000-0000-c000-000000000000",
       "resourceAccess": [{
         "id": "465a38f9-76ea-45b9-9f34-9e8b0d4b0b42",
         "type": "Scope"
       }]
     }]'
   ```
   - `00000003-0000-0000-c000-000000000000` is Microsoft Graph
   - `465a38f9-76ea-45b9-9f34-9e8b0d4b0b42` is `Calendars.Read` (delegated)

   **Copy the `appId` from the output** — this is your Client ID.

   Alternatively, use the **Azure Portal**:
   - Go to https://entra.microsoft.com → App registrations → New registration
   - Name: "Calendar CLI"
   - Supported account types: choose based on your org
   - Redirect URI: Public client → `http://localhost`
   - After creation: API permissions → Add permission → Microsoft Graph → Delegated → `Calendars.Read`

3. **Enable public client flows**:
   ```bash
   az ad app update --id YOUR_APP_ID --is-fallback-public-client true
   ```
   Or in the portal: Authentication → Advanced settings → "Allow public client flows" → Yes

4. **Grant admin consent** (if required by your organization):
   ```bash
   az ad app permission admin-consent --id YOUR_APP_ID
   ```
   Some organizations allow user self-consent — in that case this step is optional.

5. **Store the client ID for this plugin**:
   ```bash
   mkdir -p ~/.config/calendar-access
   echo '{"microsoft_client_id": "YOUR_APP_ID"}' > ~/.config/calendar-access/config.json
   ```

6. **Verify token acquisition**:
   ```bash
   TOKEN=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)
   curl -s -H "Authorization: Bearer $TOKEN" "https://graph.microsoft.com/v1.0/me/calendars" | python3 -m json.tool
   ```
   Should display your calendars.

7. **Verify calendar access**:
   ```bash
   START=$(date -u +"%Y-%m-%dT00:00:00Z")
   END=$(date -u +"%Y-%m-%dT23:59:59Z")
   curl -s -H "Authorization: Bearer $TOKEN" \
     "https://graph.microsoft.com/v1.0/me/calendarView?startDateTime=${START}&endDateTime=${END}" \
     | python3 -m json.tool
   ```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| 403 Forbidden on `/me/calendarView` | App registration missing `Calendars.Read` permission, or admin consent not granted |
| "AADSTS700016: Application not found" | Wrong client ID or app was deleted. Re-check `~/.config/calendar-access/config.json` |
| "AADSTS65001: The user or administrator has not consented" | Run `az ad app permission admin-consent --id YOUR_APP_ID` or ask your admin |
| Token expired | Run `az login --allow-no-subscriptions` again |
| "az: command not found" | Install Azure CLI: `brew install azure-cli` |
| `az account get-access-token` fails | Ensure you are logged in: `az account show`. If not, run `az login --allow-no-subscriptions` |
