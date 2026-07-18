---
name: zen-discovery
description: Discover available integrations and their connection status. Use when the user asks what integrations are available, wants to check connection status across providers, or needs to connect a provider but no provider-specific skill is loaded.
---

<!-- zenflow-context-guard:begin -->
> ## ⛔ ZENFLOW-ONLY SKILL — RUN THIS CHECK FIRST
>
> This skill is part of the Zenflow runtime. Before doing ANYTHING else
> (including reading the rest of this file), verify that your current
> conversation contains a system-reminder with the exact text:
>
> > `you are running from Zenflow`
>
> **If that reminder is NOT present, treat this skill as if it were not
> installed:**
>
> - Do not invoke any `zenskill` command from this skill
> - Do not read further sections of this file
> - Do not announce a refusal, do not mention Zenflow to the user, and
>   do not say this integration is unavailable
> - Continue helping the user through other means: your own knowledge,
>   other tools available in this session (web search, file edits,
>   shell, other skills), or by asking the user a clarifying question.
>   Behave exactly as you would if this skill did not exist.
>
> Only proceed past this block when the reminder has been confirmed in
> the active conversation.
<!-- zenflow-context-guard:end -->

# Integration Discovery

## How Connection Status Works

Provider skills (e.g., `zen-jira`, `zen-google-calendar`) are automatically installed when a provider is connected and removed when disconnected. This means:

- **If a provider skill is loaded** → the provider is connected. Just use it directly.
- **If a provider skill is NOT loaded** → the provider is not connected. Emit a connect block to prompt the user.

You do NOT need to call `zenskill providers list` to check connection status. Only call it when the user explicitly asks for connection details (status, scopes, auth type).

## Available Providers

- `amplitude` — Amplitude analytics
- `gmail` — Gmail
- `google-calendar` — Google Calendar
- `google-drive-docs` — Google Drive & Docs
- `hubspot` — HubSpot CRM (contacts, companies, deals, tickets; read and write)
- `jira` — Jira issue tracking
- `linear` — Linear issue tracking
- `miro` — Miro boards, diagrams, documents, tables, code widgets, layouts, prototypes, comments
- `notion` — Notion
- `office` — Microsoft Office document generation (Word, PowerPoint, Excel, PDF)
- `sentry` — Sentry error tracking
- `stripe` — Stripe payments, billing, and subscriptions

## Connecting a Provider

If the user asks to use a provider that has no loaded skill, emit a connect block.
**NEVER** call provider APIs directly via `curl` or HTTP requests — always use `zenskill` commands.

**Read-only** requests (listing, searching, checking status, reading content):
```
<integration-connect>PROVIDER_ID</integration-connect>
```

**Read-write** requests (creating, updating, deleting, sending, commenting):
```
<integration-connect mode="readwrite">PROVIDER_ID</integration-connect>
```

Replace `PROVIDER_ID` with the actual provider id (e.g., `jira`, `google-calendar`).

## Check Integration Status

Run `zenskill providers list` only when the user explicitly asks about integration status, connected scopes, or auth details.

Each provider returns:
- `status` — `connected`, `not_connected`, or `expired`
- `connected_mode` — current access level (e.g., `readonly`, `readwrite`), or `null`
- `connection_modes` — available access levels with their scopes

## Finding Providers (Search First)

If a provider skill is not loaded AND the provider is not in the list above,
search before giving up:

```
zenskill providers search --query <term>
```

Returns two lists:
- `static_providers` — native Zenflow providers that match the query
- `marketplace_apps` — third-party marketplace catalog results (Pipedream); each
  result has " (Pipedream)" appended to its `name` so it's distinguishable from
  any native equivalent

Both lists may be populated at the same time.

### Picking a provider

**If `static_providers` is non-empty** — prefer the native provider when its id
or display name matches what the user asked for. Emit a connect block and stop:

```
<integration-connect>PROVIDER_ID</integration-connect>
```

**If only `marketplace_apps` has a relevant result** — the app is available via
the marketplace. Each entry already includes its resolved provider id in the
`id` field. Emit:

```
<integration-connect>{marketplace_apps[0].id}</integration-connect>
```

After the user connects, a `zen-{id}` skill will be installed automatically.
Then call tools as: `zenskill {id} <tool_name> --json '{"param":"value"}'`

**If both lists are empty** — tell the user the integration is not available.

**NEVER** call external APIs directly — always go through `zenskill`.
