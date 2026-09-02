# Gotchas: the silent failures that cost the most time

Each of these fails quietly, nothing looks broken on the surface, but the agent
returns nothing, the wrong thing, or made-up data. Read this before debugging.

## 1. `CREATE OR REPLACE MCP SERVER` drops ALL grants

**Symptom:** Login succeeds, but Copilot Studio shows "No tools found." The
connection is green.

**Cause:** `CREATE OR REPLACE MCP SERVER` rebuilds the server as a new object
and drops every grant on it. Your role loses `USAGE`, so it can't see the
tools, and the tools/list call returns nothing.

**Fix:** Re-grant in the same run, every rebuild:
```sql
GRANT USAGE ON MCP SERVER <db>.<schema>.<server> TO ROLE <your_role>;
```
Confirm with `SHOW GRANTS ON MCP SERVER ...`. Prefer `ALTER MCP SERVER` over
`CREATE OR REPLACE` when possible.

## 2. Cortex Analyst returns SQL, not executed rows

**Symptom:** The agent shows a SQL query or an "interpretation" but no real
numbers, or it invents plausible-looking numbers.

**Cause:** `CORTEX_ANALYST_MESSAGE` is text-to-SQL. It returns the *query*, not
the *result rows*. With no data to show, a weak agent hallucinates.

**Fix:** Add a second tool, `SYSTEM_EXECUTE_SQL` (e.g. `run_sql`). Instruct the
agent to (1) call sales_analyst to get SQL, then (2) pass that SQL to run_sql to
execute it and return real rows, and to answer only from those rows.

## 3. Diagnose "login works but no tools" with query history

The key diagnostic. When tools don't appear, check Snowflake:
```sql
-- Did the login reach Snowflake?
SELECT * FROM TABLE(INFORMATION_SCHEMA.LOGIN_HISTORY(
  DATEADD('minute',-15,CURRENT_TIMESTAMP()), CURRENT_TIMESTAMP()));
-- Did any query actually run?
SELECT USER_NAME, ROLE_NAME, EXECUTION_STATUS, LEFT(QUERY_TEXT,120), START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY(RESULT_LIMIT=>20))
ORDER BY START_TIME DESC;
```
- Login yes + query yes → discovery works; issue is client-side display.
- Login yes + query no → a permission gap (usually #1), NOT an auth failure.
- No login at all → the request never reached Snowflake; check Server URL.

## 4. The per-tool toggle

A discovered tool still needs its **individual toggle** ON in the Copilot Studio
Tools list. A tool can be present but disabled, and the agent then reports it
has no access.

## 5. Server URL format

Regionless host, hyphenated, no trailing slash, no `/sse` or `/mcp`:
```
https://<org>-<account>.snowflakecomputing.com/api/v2/databases/<DB>/schemas/<SCHEMA>/mcp-servers/<SERVER>
```
Confirm the exact host with `SELECT SYSTEM$ALLOWLIST();` (use the
`SNOWFLAKE_DEPLOYMENT_REGIONLESS` entry).

## 6. Cortex is blocked on Snowflake trials

Tool discovery works but every call fails ("No tool result received calling
Cortex Agent"). Add a card (converts to pay-as-you-go, keeps free credits) or
ask Snowflake support to enable Cortex.

## 7. Cost control

- Auto-suspend: `ALTER WAREHOUSE COMPUTE_WH SET AUTO_SUSPEND = 60;`
- Resource monitor as a hard brake (see `snowflake/01_setup.sql`).
- A "pending" ~$20 charge when you add a card is a temporary auth hold, not
  usage. Check `Admin → Cost Management` for real dollars; free credits are used
  first.
