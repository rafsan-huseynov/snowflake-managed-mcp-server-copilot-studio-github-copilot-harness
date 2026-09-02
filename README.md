# Connect Snowflake to Copilot Studio with a Managed MCP Server

A complete, step-by-step guide to connect a **Snowflake-managed MCP server** to
a **Microsoft Copilot Studio** agent, with per-user security through
**Microsoft Entra OAuth**.

> Note: **Microsoft Copilot Studio** (used here to build the agent) is a
> separate product from **GitHub Copilot**. This guide builds an agent powered
> by the **GitHub Copilot harness**, a Copilot Studio authoring/runtime option
> with natural-language-first authoring and enhanced orchestration. See
> [Agents powered by the GitHub Copilot harness](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agents-experience/overview).

Most enterprise data lives in Snowflake. This repo shows how to let a Copilot
Studio agent query it live: a user asks a question in plain English, the agent
turns it into SQL, runs it in Snowflake, and returns real numbers, tables, and
charts, while every query runs as the signed-in user's own Snowflake identity.

> **No credentials or personal data are in this repo.** Every ID, host, secret,
> and email is a `<PLACEHOLDER>`. Replace them with your own. Sample data is
> synthetic and company names are generic (Contoso / Northwind).

## What you build

```
User (Copilot Studio)
        |  asks a plain-English question, signed in with their Entra identity
        v
Copilot Studio agent
        |  calls the MCP tools
        v
Snowflake-managed MCP server  ->  two tools:
        |-- sales_analyst  (Cortex Analyst: plain English -> SQL)
        \-- run_sql        (executes the SQL, returns REAL rows)
        |  every query runs as the signed-in user's Snowflake role (RBAC)
        v
Snowflake data (Cortex Analyst over a semantic view)
```

## Why two tools

Cortex Analyst (`CORTEX_ANALYST_MESSAGE`) is text-to-SQL: it returns the SQL,
not the executed rows. Pair it with `run_sql` (`SYSTEM_EXECUTE_SQL`) so the
agent runs that SQL and answers with **real data** instead of guessing.

## Steps (in order)

1. **[Snowflake setup](snowflake/01_setup.sql)** - tables + synthetic sample
   data, cost controls.
2. **[Semantic view + MCP server + RBAC](snowflake/02_semantic_view_and_mcp.sql)**
   - the semantic view, the MCP server with two tools, the role and grants, and
   the delegate user.
3. **[Entra OAuth](entra/README.md)** - resource app + client app, the
   `session:role-any` scope, admin consent.
4. **[Snowflake trust](snowflake/03_external_oauth.sql)** - teach Snowflake to
   trust Entra tokens and map them to users.
5. **[Copilot Studio](copilot-studio/README.md)** - add the MCP server as a tool
   (Manual OAuth), close the redirect-URI loop, connect, and test.

## Read this first

Before you debug anything, read **[docs/gotchas.md](docs/gotchas.md)**.
The two that cost the most time:

- `CREATE OR REPLACE MCP SERVER` **drops all grants** -> "No tools found" while
  login still succeeds. Re-grant `USAGE` every rebuild.
- **Cortex Analyst returns SQL, not rows** -> add `run_sql`
  (`SYSTEM_EXECUTE_SQL`) so the agent gets real data.

## Requirements

- A Snowflake account with **Cortex enabled** (not a plain trial - Cortex is
  blocked on trials; add a card or ask Snowflake support).
- A Microsoft 365 tenant where you can create Entra app registrations and grant
  admin consent.
- Copilot Studio access.

## License

MIT - see [LICENSE](LICENSE).

**This MIT license covers the code and docs in this repo only.** Building,
testing, and running the agent in Copilot Studio's GitHub Copilot harness
consumes **Copilot Credits** (usage-based billing based on task complexity).
You need either **pay-as-you-go** (Azure subscription billing policy) or a
**Copilot Credits prepurchase plan** to use it. See
[Licensing for agents powered by the standard harness](https://learn.microsoft.com/en-us/microsoft-copilot-studio/billing-licensing)
and [Manage costs for agents powered by the GitHub Copilot harness](https://learn.microsoft.com/en-us/power-platform/admin/manage-copilot-studio-copilot-credits-capacity).
Copilot Credits capacity is separate from, and required in addition to, this
repo's MIT license.

## Disclaimer

Provided as-is for educational purposes. Product features and pricing change.
Verify licensing and cost with Microsoft and Snowflake before any production or
customer deployment.
