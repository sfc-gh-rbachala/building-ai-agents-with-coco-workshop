# Workshop Guide — v2
## Build, Extend, and Expose a Production AI Agent

**This is the v2 guide.** It runs in ~75 minutes and delivers the MCP Server as a
live core step — not take-home. Designed for technical audiences who are comfortable
moving fast.

If you're in a larger or mixed-level room with a 60-minute slot, use
[`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) (v1) instead. See [`VERSION.md`](VERSION.md)
for the level comparison.

**Follow this during the session.** Event-specific details — date, venue, and your
trial signup link — are on your event page in [`events/`](events/).

Facilitated by **Richie Bachala**, Snowflake.

---

## Before You Start

You need two things. Both are covered on your event page.

1. **A Snowflake trial account**, created with your **event-specific signup link**.
   That link activates the AI features this workshop uses, and only inside a short
   window around the event date. A generic trial won't work.
2. **The CoCo CLI installed** — `cortex --version` should print a version number.

```bash
# macOS / Linux / WSL
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh

# Windows (PowerShell)
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

---

## The Goal

By the end of this session you will have **built, deployed, and connected a
production AI agent.**

**GitTrend** — grounded in 107M real GitHub events, queryable from any MCP client.

You will not write SQL by hand. CoCo writes every statement; you direct it and review
what it produces.

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  107M real GitHub events (from S3)
CoCo CLI                          →  writes the code (your terminal)
V_TRENDING_AI_REPOS               →  trending AI repos by star activity
AI_COMPLETE                       →  turns SQL results into language
GITHUB_REPO_SEARCH                →  Cortex Search Service (semantic index)
GITTREND                          →  Cortex Agent (search + chart + system prompt)
GITTREND_MCP                      →  MCP Server — exposes GitTrend to any AI tool
GITTREND_MCP_OAUTH                →  OAuth security integration
```

> **Stuck at any point?** [`CHECKPOINTS.sql`](CHECKPOINTS.sql) has the fallback SQL
> for every step. Paste it into a Snowsight worksheet and you'll land in the same
> place. Falling back is not failing — it keeps you with the group.

---

# Step 0 — Set the Context

**⏱ ~10 min** | Do this before everything else.

### Create your project folder and `AGENTS.md`

```bash
mkdir gittrend-workshop && cd gittrend-workshop
```

Create a file called `AGENTS.md` in that folder:

```markdown
# AGENTS.md
Account: <your-snowflake-account-identifier>
Role: ACCOUNTADMIN
Warehouse: WORKSHOP_WH
Database: GITTREND_DB
Schema: GITTREND_DB.PUBLIC

Do NOT modify: production tables, RBAC roles, cost-sensitive resources.
Always use WAREHOUSE = WORKSHOP_WH in DDL.
Always use fully qualified object names (DB.SCHEMA.OBJECT).
Source data is read-only: GITTREND_DB.PUBLIC.GITHUB_EVENTS
```

> **Why `AGENTS.md` matters:** CoCo reads this file at the start of every session.
> It knows your account, your warehouse, and your constraints without you
> re-explaining them. Keeping it under 200 lines holds compliance near 100%. This is
> the single most transferable thing you'll take home — this pattern works on any
> dataset in your organization.

### Start CoCo

From inside `gittrend-workshop/`:

```bash
cortex
```

On first launch a setup wizard walks you through creating a Snowflake connection.

> **No connections found?** Select **Sync from app.snowflake.com** — this pulls
> your connection directly from your browser session (Snowsight). It's the fastest
> path and works without entering anything manually.
>
> If you prefer to enter credentials manually: account identifier format is
> `orgname-accountname`, found in Snowsight under Admin → Accounts.

> **Already have a Snowflake CLI connection?** CoCo shares the same
> `~/.snowflake/connections.toml`. It will list your existing connections — just
> pick one.

Once connected, CoCo loads your `AGENTS.md` automatically.

**Checkpoint:** you see **`Loaded 1 instruction file`** below the connection panel.
That line is your confirmation — not the header itself.

> **`AGENTS.md` not loaded?** You ran `cortex` from the wrong directory. It has to
> be the folder holding the file.

> **Useful mid-session:** `/compact` summarizes a long conversation to free up
> context. `cortex --sql-read-only` prevents accidental writes.

---

# Step 1 — Load the Data

**⏱ ~7 min, runs in the background — move on immediately**

Paste this prompt into CoCo:

```
Run the setup SQL: create GITTREND_DB, WORKSHOP_WH (Small, auto-suspend 60s),
load 107M GitHub events from s3://sfquickstarts/vhol_building_ai_agents_with_coco/
into GITHUB_EVENTS table. Enable cross-region Cortex. Verify the count.
```

CoCo creates the database, warehouse, stage, and table, runs `COPY INTO`, then
verifies the row count. **The load takes ~4 minutes.** Don't sit and watch it —
move straight to Step 2. The load runs server-side inside Snowflake.

**Checkpoint:** `SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS` returns
~107,752,158 rows.

> **CoCo asking for confirmation at every statement?** Run the SETUP block from
> [`CHECKPOINTS.sql`](CHECKPOINTS.sql) in a Snowsight worksheet in parallel. Same
> result, less friction.

---

# Step 2 — Build the GitTrend Agent

**⏱ ~15 min** | Five prompts. Fire them in order.

### ① Explore the schema

```
I have a table called GITTREND_DB.PUBLIC.GITHUB_EVENTS loaded from the
GitHub Archive. Explore it: describe the key columns, explain what types of
GitHub events are tracked. Tell me which columns would be most useful for
finding trending AI and ML repositories by star activity.
```

**Checkpoint:** CoCo works out that `WatchEvent` means "a repo was starred," and
points you at `REPO_NAME`, `CREATED_AT`, and `EVENT_TYPE`.

That inference is the point. Nothing in the schema says "star." CoCo read the data
and figured it out.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 1

### ② Build `V_TRENDING_AI_REPOS`

```
Using GITTREND_DB.PUBLIC.GITHUB_EVENTS:

Create a view called GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS that finds repos
that gained the most stars in the last 30 days. The data in this table only
goes through June 18, 2026 — use that as the end of the 30-day window, not
CURRENT_TIMESTAMP.

Where the repo name suggests AI, ML, LLM, GPT, agent, MCP, or open source
(names containing "open"). Include exactly these columns, with these names:
repo_name, description (use the repo name for this too), stars_gained,
first_star_at, last_star_at. Only include repos with 10 or more stars gained.

Then query the view to show the top 20 repos by stars gained, descending.
```

**The moment:** look at what's at the top of your list. That's 107M real GitHub
events surfacing what the developer community was actually building — signal from
the archive, not a model's training memory.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 2

### ③ Add `AI_COMPLETE`

```
Take the view we just created. Wrap the results in a call to AI_COMPLETE so
that instead of returning raw rows, it returns a natural language summary.

The summary should:
- Name the top 3 trending AI repos and why they're gaining momentum
- Note any patterns across language, topic, or category
- Be concise — 3 to 4 sentences max

Use the 'claude-sonnet-4-6' model.
Show me the query you ran and the query results.
```

**Checkpoint:** the query returns a paragraph, not rows.

> **Use `AI_COMPLETE`, not `CORTEX.COMPLETE`.** `CORTEX.COMPLETE` is deprecated
> and being retired in 2026. `AI_COMPLETE` is the function going forward.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 3

### ④ Create the Cortex Search Service

```
Create a Cortex Search Service called GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
using the V_TRENDING_AI_REPOS view we just created.

Search on the description column. Include repo_name and stars_gained as
attributes. Use WORKSHOP_WH and a target lag of 1 hour.
```

**Fire this immediately and move to ⑤ — they overlap.** The service takes ~30
seconds to become active while you create the agent.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 4

### ⑤ Create the GITTREND Agent

```
Create a Cortex Agent called GITTREND_DB.PUBLIC.GITTREND that:

1. Uses GITHUB_REPO_SEARCH (the Cortex Search service we just built)
   as a search tool for finding relevant repos
2. Uses auto as the orchestration model (Snowflake selects the best available)
3. Includes a data_to_chart tool so it can generate visualizations
4. Has a system prompt that tells it:
   - It is GitTrend, a GitHub trend analyst
   - Its data covers GitHub star activity from May 19 to June 18, 2026, and does
     not update. When someone says "last 30 days" or "this month", it should
     interpret that as this fixed window and say so in its answer
   - It should answer questions about trending repos, emerging technologies,
     and developer community activity
   - It should always cite the specific repos it's drawing from
   - In its response formatting, it should be concise and data-driven,
     use bullet points for repo lists, and always mention the repo name
     in owner/repo format with the star count

Create it in GITTREND_DB.PUBLIC.
```

**Checkpoint:** `SHOW AGENTS IN SCHEMA GITTREND_DB.PUBLIC` returns `GITTREND`.

> **On model selection:** use `auto`, not a specific model name. Snowflake picks
> the best model available for your account and region — you never have to update
> the agent config when something better lands.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 5

**Quick preview before Step 3:** open GitTrend in Snowsight to confirm it's working.

Left nav → AI & ML → Agents → `GITTREND` → **Preview** tab

Ask: *"Show me a bar chart of the top 10 repos by stars gained."*

That triggers `data_to_chart` — the agent decides on its own when to use it. Now
let's give it an endpoint the whole world can reach.

> **CoWork showing 'Something went wrong'?** Use the **Preview** tab instead —
> it's on the same agent detail page and works identically for our purposes.
> CoWork can be intermittent on trial accounts; Preview is the reliable fallback.

---

# Step 3 — Wire the MCP Server

**⏱ ~18 min** | New territory — slow down here.

This takes GitTrend from a Snowflake-only agent to something any AI tool can call.
Three parts.

> **What's the Snowflake-managed MCP Server?** A DDL object that exposes your
> agents, search services, and analysts to any MCP-compatible client — Claude
> Desktop, Cursor, VS Code, or your own app. No separate infrastructure, no Docker.
> You create it; clients connect and discover your tools automatically.

### Part 1 — Create the MCP Server

```
Create an MCP Server called GITTREND_DB.PUBLIC.GITTREND_MCP that exposes
the GITTREND agent (GITTREND_DB.PUBLIC.GITTREND) as a tool.

Tool name: "gittrend"
Tool type: CORTEX_AGENT_RUN
Title: "GitTrend — GitHub Trend Analyst"
Description: "GitHub trend analyst with 30 days of real star activity data.
Ask it about trending repos, emerging AI/ML projects, and developer momentum."
```

CoCo generates the `CREATE OR REPLACE MCP SERVER` DDL. Once it runs:

Verify: `SHOW MCP SERVERS IN SCHEMA GITTREND_DB.PUBLIC;`

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 6

### Part 2 — Set up OAuth

MCP clients authenticate via OAuth. The redirect URI below is for **claude.ai
(web)**. Claude Desktop and Cursor each show their own redirect URI during setup —
use theirs instead.

```sql
CREATE OR REPLACE SECURITY INTEGRATION GITTREND_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback';
```

Get your client credentials — **save these now**, you need them in Part 3:
```sql
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('GITTREND_MCP_OAUTH');
```

Save the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET`.

Set your default role and warehouse (required for MCP OAuth sessions):
```sql
SET MY_USER = CURRENT_USER();
ALTER USER IDENTIFIER($MY_USER) SET DEFAULT_ROLE = 'ACCOUNTADMIN' DEFAULT_WAREHOUSE = 'WORKSHOP_WH';
```

### Part 3 — Connect a client

Your MCP Server URL:
```
https://<your-account-url>/api/v2/databases/GITTREND_DB/schemas/PUBLIC/mcp-servers/GITTREND_MCP
```

> **Finding your account URL:** it's
> `https://<orgname>-<accountname>.snowflakecomputing.com`, from Admin → Accounts
> in Snowsight. Use **hyphens** in the hostname, never underscores — underscores
> cause MCP connection failures in several clients.

**Easiest path — CoCo Desktop.** It auto-discovers MCP Servers in your account and
skips OAuth entirely, because it's already authenticated through your Snowflake
connection. Open CoCo Desktop, connect to the same account, and GitTrend appears
in your tools.

**claude.ai (web):**
1. claude.ai → Settings → Connectors → **Add custom connector**
2. Name: `GitTrend` | URL: your MCP Server URL above
3. Enter the client ID and secret from Part 2
4. Add → authenticate in the browser popup

**Cursor** — edit `~/.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "gittrend": {
      "url": "https://<your-account-url>/api/v2/databases/GITTREND_DB/schemas/PUBLIC/mcp-servers/GITTREND_MCP",
      "auth": {
        "CLIENT_ID": "<your-oauth-client-id>",
        "CLIENT_SECRET": "<your-oauth-client-secret>"
      }
    }
  }
}
```
Then Cursor Settings → MCP → `gittrend` → **Sign in**.

---

# Run It

**⏱ ~8 min** | Slow down. Let it land.

Open GitTrend from your MCP client — Claude Desktop, Cursor, or CoCo Desktop.
GitTrend should appear in your tools list.

Ask it:

> *"What's the fastest-growing AI project in the last 30 days?"*

That answer is grounded in 107 million real GitHub events. In an account that was
empty when you sat down.

GitTrend holds context across turns (Cortex Agent Threads):

```
What programming languages dominate trending AI repos right now?

Is there anything blowing up around MCP or agentic AI this month?

Compare the top 5 repos — what do they have in common?

Are there any surprise breakouts — repos nobody knows yet but are gaining fast?

Show me a bar chart of the top 10 repos by stars gained.
```

> **That last one triggers Data to Chart.** GitTrend renders a visualization
> inline. That's the `data_to_chart` tool you added in Step 2⑤ — the agent
> decided on its own when to use it.

> **Note on the data window:** the archive snapshot runs May 19 – June 18, 2026.
> "Last 30 days" means that window, not today. You told the agent this in Step 2⑤,
> so it will say so in its answer.

---

## What You Built

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  —  107M real GitHub events loaded from S3
V_TRENDING_AI_REPOS               —  trending AI repo view by star activity
GITHUB_REPO_SEARCH                —  Cortex Search index
GITTREND                          —  Cortex Agent: search + chart + system prompt
GITTREND_MCP                      —  MCP Server: exposes GitTrend to any AI tool
```

CoCo wrote every SQL statement. You directed it.

**Now do it on your own data.** Replace `GITHUB_EVENTS` with your support tickets,
sales pipeline, product telemetry, or internal docs. Same four steps, same prompts,
different schema. That's the part worth taking to work on Monday.

---

## Take It Further

**Add Cortex Analyst via a Semantic View.** Build a Semantic View over your data
and add it as a `CORTEX_ANALYST_MESSAGE` tool. Your clients can then ask structured
analytical questions alongside conversational search. Agents generate SQL directly
from semantic views — faster and more accurate than the older two-step approach.

**Add MCP Connectors (outbound).** You built an MCP Server, which is inbound. MCP
Connectors are the opposite direction — your agent calling *out* to Jira,
Salesforce, or your APIs. Picture asking GitTrend: *"Open a Jira ticket for the
top trending repo we should evaluate."*

**Add an Agent Skill.** Skills are modular instruction sets (`SKILL.md` files) that
teach your agent new behaviors without touching its core spec. Upload one to a
stage, attach it, and the agent follows that playbook when relevant questions come
in — no redeployment. See [`sample_weekly_digest_skill.md`](sample_weekly_digest_skill.md)
and the [Agent Skills docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-skills).

**Add a SQL execution tool.** Add `SYSTEM_EXECUTE_SQL` to your MCP Server and any
client can run ad-hoc queries against your account. Useful for power users who
want raw access next to the agent.

---

## Resources

- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)
