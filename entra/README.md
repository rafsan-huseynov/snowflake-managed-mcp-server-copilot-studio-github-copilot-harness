# Step 3: Microsoft Entra OAuth setup

You create **two** app registrations in Microsoft Entra:

- **Resource app** — represents Snowflake (the thing being protected). It
  exposes the `session:role-any` scope that Snowflake checks for.
- **Client app** — represents the caller (Copilot Studio). It requests that
  scope and holds a client secret.

Entra is the OAuth **authorization server** in this design: it issues the
access token. Snowflake is the **resource server** — it validates that token
(via the `EXTERNAL_OAUTH` integration in
[`03_external_oauth.sql`](../snowflake/03_external_oauth.sql)) and maps its
`upn` claim to a Snowflake user; it never issues tokens itself.

> Replace every `<PLACEHOLDER>` with your own value. Never commit secrets.

## 3.1 Resource app (Snowflake OAuth Resource)

1. Entra admin center → **App registrations** → **New registration**.
2. Name: `Snowflake OAuth Resource`. Accounts in this org only. No redirect URI.
3. **Register**, then from **Overview** copy:
   - Application (client) ID → `<RESOURCE_APP_CLIENT_ID>`
   - Directory (tenant) ID → `<TENANT_ID>`
4. **Expose an API**:
   - Set **Application ID URI** to the default `api://<RESOURCE_APP_CLIENT_ID>`.
   - **Add a scope**:
     - Scope name: `session:role-any`
     - Who can consent: **Admins and users**
     - Admin consent display name: `Access Snowflake`
     - Admin consent description: `Allow the app to access Snowflake on behalf of the signed-in user`
     - State: **Enabled**

## 3.2 Client app (Snowflake OAuth Client)

1. **App registrations** → **New registration**.
2. Name: `Snowflake OAuth Client`. Accounts in this org only. No redirect URI yet.
3. **Register**, copy Application (client) ID → `<CLIENT_APP_CLIENT_ID>`.
4. **Certificates & secrets** → **New client secret**. Copy the **Value**
   immediately (shown once) → `<CLIENT_SECRET_VALUE>`.
5. **API permissions** → **Add a permission** → **My APIs** →
   pick the Resource app → **Delegated** → check `session:role-any` → **Add**.
6. Click **Grant admin consent for <tenant>**. Wait for the green check.

> Tip: a brand-new resource app can take a few minutes to appear under
> "My APIs". If it's missing, either wait and refresh, or authorize the client
> from the Resource app side (**Expose an API → Add a client application**),
> then add the delegated permission on the client via its **Manifest**
> `requiredResourceAccess` (use the scope's `id` from the resource app's
> `oauth2PermissionScopes`).

## 3.3 Redirect URI (added later, on purpose)

The redirect URI does **not** exist until Copilot Studio generates the connector. You add it to the **Client app → Authentication →
Add a platform → Web** *after* the connector is created. Adding it too early is
impossible; adding it under the wrong platform (SPA/mobile) fails silently.

## 3.4 Values you now have

| Placeholder | Where it came from |
|---|---|
| `<TENANT_ID>` | Resource app Overview → Directory (tenant) ID |
| `<RESOURCE_APP_CLIENT_ID>` | Resource app Overview → Application (client) ID |
| `<CLIENT_APP_CLIENT_ID>` | Client app Overview → Application (client) ID |
| `<CLIENT_SECRET_VALUE>` | Client app → Certificates & secrets → Value |

Next: run [`../snowflake/03_external_oauth.sql`](../snowflake/03_external_oauth.sql)
to make Snowflake trust these tokens, then go to
[Copilot Studio](../copilot-studio/README.md).

## Further reading

- [Wiring up a Snowflake-managed MCP server in Copilot Studio](https://microsoft.github.io/mcscatblog/posts/snowflake-mcp-copilot-studio/) — Microsoft Copilot Studio CAT team walkthrough covering the same setup end to end.
