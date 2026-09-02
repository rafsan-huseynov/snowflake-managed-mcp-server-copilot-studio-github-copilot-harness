# Step 5: Add the MCP server in Copilot Studio

Connect your Snowflake MCP server to a Copilot Studio agent as an MCP tool,
using **Manual OAuth**. Every query runs as the signed-in user, mapped to their
Snowflake role.

## 4.1 Get your Snowflake account host

In Snowflake, run:
```sql
SELECT SYSTEM$ALLOWLIST();
```
Use the `SNOWFLAKE_DEPLOYMENT_REGIONLESS` entry — a hyphenated host like
`<org>-<account>.snowflakecomputing.com`.

Your **Server URL** is:
```
https://<ORG>-<ACCOUNT>.snowflakecomputing.com/api/v2/databases/RETAIL_SALES_DB/schemas/SALES_SCHEMA/mcp-servers/SALES_MCP_SERVER
```
No trailing slash. No `/sse` or `/mcp` suffix. Hyphen in the host, not underscore.

## 4.2 Create the agent and add the MCP tool

1. In Copilot Studio, create an agent (e.g. "Product Insights Agent").
2. Open it → **Tools** → **Add tool** → **Model Context Protocol** → add new.
3. Fill in:
   - **Server name:** `Snowflake Sales MCP`
   - **Server description:** short, user-friendly.
   - **Server URL:** the URL from 4.1.
   - **Authentication:** OAuth 2.0
   - **Configuration type:** **Manual** ← important. Snowflake does NOT support
     OAuth Dynamic Client Registration; Dynamic Discovery fails silently.

## 4.3 Manual OAuth fields

| Field | Value |
|---|---|
| Client ID | `<CLIENT_APP_CLIENT_ID>` |
| Client secret | `<CLIENT_SECRET_VALUE>` |
| Authorization URL | `https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/authorize` |
| Token URL | `https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token` |
| Refresh URL | `https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token` (same as Token URL) |
| Scopes | `api://<RESOURCE_APP_CLIENT_ID>/session:role-any offline_access` |

Click **Create**.

## 4.4 Close the redirect-URI loop (the chicken-and-egg step)

Creating the tool generates a **custom connector** in Power Platform, and that
connector generates a **redirect URL** that doesn't exist until now.

1. Open **make.powerapps.com** → switch to the same environment.
2. **More** → **Custom connectors** → open your Snowflake connector (edit).
3. **Security** tab → bottom of the OAuth 2.0 section → copy the **Redirect URL**
   (`https://global.consent.azure-apim.net/redirect/...`).
4. In Entra → **Client app** → **Authentication** → **Add a platform** →
   **Web** → paste the redirect URL → **Configure**.

> Must be added under **Web**, not SPA or mobile — anything else fails silently
> at token exchange. If you re-create the connector later, it generates a
> **new** redirect URL; add that one too.

## 4.5 Connect (twice) and discover tools

There are **two** connections and both must succeed:

- **Maker connection:** in the tool's details, create a new connection, sign in.
  Copilot Studio then discovers the tools (`sales_analyst`, `run_sql`). Make sure
  **both tool toggles are ON**.
- **End-user (test pane) connection:** the test pane runs as the end user and
  needs its own connection. On first tool use it prompts "Let's get you
  connected" — open connection manager, sign in with the user whose UPN matches
  the Snowflake `LOGIN_NAME`, then retry.

## 4.6 Instruct the agent (two-step flow)

In the agent's **Instructions**, tell it to chain the two tools:

```
You answer questions about retail sales data.

For any sales question, do these two steps in order:
1. Call sales_analyst with the user's plain question. It returns a SQL query.
2. Pass that exact SQL to run_sql to execute it and get the real data rows.

Answer using only the rows run_sql returns. Never invent or guess numbers.
If run_sql returns no rows, say you could not retrieve the data.
Present results as a short summary plus a simple table, and a chart when useful.
```

## 4.7 Test

Start a new test session and ask:
- "List all our products."
- "What is our total revenue by product category? Show it as a bar chart."
- "Who are our top 5 customers by total spending?"

You should get real data, tables, and charts (built by the agent's skills),
all from live Snowflake queries.

## Verify it ran in Snowflake

```sql
USE ROLE ACCOUNTADMIN;
SELECT USER_NAME, ROLE_NAME, EXECUTION_STATUS, LEFT(QUERY_TEXT,80) AS Q, START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(RESULT_LIMIT => 10))
ORDER BY START_TIME DESC;
-- Look for DELEGATE_USER running as SALES_USER, EXECUTION_STATUS = SUCCESS.
```
