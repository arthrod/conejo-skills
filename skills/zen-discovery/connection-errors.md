# Handling Connection Errors

> **IMPORTANT**: These instructions apply ONLY to errors returned by the `zenskill` CLI
> (JSON envelope with `ok: false` and an `error_code` field). Do NOT apply these rules
> to errors from `curl`, direct API calls, or any other tool. If you are not using `zenskill`,
> these instructions do not apply. Always use `zenskill` commands — never call provider
> APIs directly via `curl` or HTTP requests.

## Not Connected / Expired

If a `zenskill` command fails with `error_code: "AUTH_REQUIRED"` or `"AUTH_EXPIRED"`:

1. Do NOT retry the command — it will fail again
2. Tell the user the integration needs to be connected
3. Check the `required_mode` field in the error JSON — it tells you exactly which mode to request
4. Emit a connect block with the correct mode:

**If `required_mode` is `"readwrite"`:**
```
<integration-connect mode="readwrite">PROVIDER_ID</integration-connect>
```

**If `required_mode` is `"readonly"` or absent:**
```
<integration-connect>PROVIDER_ID</integration-connect>
```

Replace `PROVIDER_ID` with the actual provider id (e.g., `jira`, `linear`, `google-calendar`).

Example — a write command fails because Google Calendar is not connected:

```json
{"ok":false,"error":"Authentication required for Google Calendar.","error_code":"AUTH_REQUIRED","required_mode":"readwrite"}
```

Response:

```
I need to connect Google Calendar with write access to create events. Please connect it to continue.

<integration-connect mode="readwrite">google-calendar</integration-connect>
```

After the user connects, retry the original command.

## Scope Upgrade (SCOPE_MISSING)

If a `zenskill` command fails with `error_code: "SCOPE_MISSING"`, the provider is connected but lacks the required scopes (typically because it was connected in read-only mode):

1. Do NOT retry the command — it will fail again
2. Tell the user they need to upgrade access
3. The `required_mode` field in the error JSON tells you which mode is needed (typically `"readwrite"`)
4. Emit the block with the required mode:

```
<integration-connect mode="readwrite">PROVIDER_ID</integration-connect>
```

Example — a write command fails with SCOPE_MISSING:

```
Google Calendar is connected in read-only mode, but creating events requires read-write access. Please upgrade the connection.

<integration-connect mode="readwrite">google-calendar</integration-connect>
```

After the user upgrades, retry the original command.

### Slack-specific: SCOPE_MISSING

For Slack (`slack_bot`), SCOPE_MISSING means the app manifest needs to be updated with additional scopes — this is NOT a standard OAuth reconnect. Emit a `<slack-scope-upgrade />` tag instead of `<integration-connect>`:

```
The Slack app needs the `channels:read` scope to read channel messages. Please update the app to add the required permissions.

<slack-scope-upgrade />
```

This renders an "Update App" card that walks the user through updating the Slack app manifest and reconnecting.
