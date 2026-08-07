# Workshop Guide
## Build a Production AI Agent with Snowflake CoCo

**Follow this during the session.** Event-specific details — date, venue, and your trial signup link — are on your event page in [`events/`](events/).

Facilitated by **Richie Bachala**, Snowflake.

---

## Before You Start

You need two things. Both are covered on your event page.

1. **A Snowflake trial account**, created with your **event-specific signup link**. That link activates the AI features this workshop uses, and only inside a short window around the event date. A generic trial won't work.
2. **The CoCo CLI installed** — `cortex --version` should print a version number.

```bash
# macOS / Linux / WSL
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh

# Windows (PowerShell)
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

---

## The Goal

Build **GitTrend** — an AI agent grounded in 107M real GitHub events that answers plain-English questions about what developers are actually building.

You will not write SQL by hand. CoCo writes every statement; you direct it and review what it produces.

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  107M real GitHub events (from S3)
CoCo CLI                          →  writes the code (your terminal, not Snowsight)
V_TRENDING_AI_REPOS               →  trending AI repos by star activity
AI_COMPLETE                       →  turns SQL results into language
GITHUB_REPO_SEARCH                →  Cortex Search Service (semantic index)
GITTREND                          →  Cortex Agent (search + chart + system prompt)
```

> **Stuck at any point?** [`CHECKPOINTS.sql`](CHECKPOINTS.sql) has the fallback SQL for every step. Paste it into a Snowsight worksheet and you'll land in the same place. Falling back is not failing — it keeps you with the group.

---

# Step 1 — Set the Context

**⏱ ~10 min**

This is the foundation. Do it before anything else.

### 1a. Create your project folder and `AGENTS.md`

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

> **Why `AGENTS.md` matters:** CoCo reads this file at the start of every session. It knows your account, your warehouse, and your constraints without you re-explaining them. Keeping it under 200 lines holds compliance near 100%. This file is the reason this workflow moves faster than clicking through a UI — and it's the single most transferable thing you'll take home from this session.

### 1b. Connect to Snowflake and start CoCo

From inside `gittrend-workshop/`:

```bash
cortex
```

On first launch a setup wizard walks you through creating a Snowflake connection — enter your account identifier, username, and password.

> **Account identifier format:** `orgname-accountname`. Find it in Snowsight under Admin → Accounts.

> **Already have a Snowflake CLI connection?** CoCo shares the same `~/.snowflake/connections.toml`. It will list your existing connections — just pick one.

Once connected, CoCo loads your `AGENTS.md` automatically. You'll see it confirmed in the session header.

**Checkpoint:** CoCo is running and the session header shows `AGENTS.md` loaded.

> **`AGENTS.md` not loaded?** You ran `cortex` from the wrong directory. It has to be the folder holding the file.

> **Useful mid-session:** `/compact` summarizes a long conversation to free up context. `cortex --sql-read-only` (or `/sql-writes off`) prevents accidental writes — worth knowing before you point CoCo at anything real.

---

# Step 2 — Load the Data

**⏱ ~5 min, and it runs in the background**

Paste this prompt into CoCo:

```
Run the following setup SQL in my Snowflake account:
- Create GITTREND_DB database and PUBLIC schema
- Create WORKSHOP_WH warehouse (Small size, auto-suspend 60s)
- Enable Cortex AI cross-region with ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION'
- Create a JSON file format (STRIP_OUTER_ARRAY = TRUE, COMPRESSION = GZIP) and an S3 stage pointing to s3://sfquickstarts/vhol_building_ai_agents_with_coco/
- Create GITHUB_EVENTS table with columns: RAW VARIANT, EVENT_ID STRING, EVENT_TYPE STRING, CREATED_AT TIMESTAMP, ACTOR_LOGIN STRING, ACTOR_ID NUMBER, REPO_NAME STRING, REPO_ID NUMBER, ORG_LOGIN STRING, IS_PUBLIC BOOLEAN
- COPY INTO the table using a transformation query that extracts fields from the raw JSON:
  RAW = $1, EVENT_ID = $1:id::STRING, EVENT_TYPE = $1:type::STRING,
  CREATED_AT = $1:created_at::TIMESTAMP, ACTOR_LOGIN = $1:actor:login::STRING,
  ACTOR_ID = $1:actor:id::NUMBER, REPO_NAME = $1:repo:name::STRING,
  REPO_ID = $1:repo:id::NUMBER, ORG_LOGIN = $1:org:login::STRING,
  IS_PUBLIC = $1:public::BOOLEAN
  Use pattern .*json.gz
- Run SELECT COUNT(*) to verify (~107M rows expected)
```

CoCo writes and runs the setup SQL. **The load takes about 4 minutes.** Don't sit and watch it — move straight to Step 3. The load runs server-side inside Snowflake.

**Checkpoint:** `SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS` returns ~107,752,158 rows.

> **CoCo asking for confirmation at every statement?** Run the SETUP block from [`CHECKPOINTS.sql`](CHECKPOINTS.sql) in a Snowsight worksheet in parallel. Same result, less friction.

---

# Step 3 — Explore and Build

**⏱ ~15 min**

### 3a. Let CoCo read the schema

```
I have a table called GITTREND_DB.PUBLIC.GITHUB_EVENTS loaded from the GitHub Archive.
Explore it: describe the key columns, explain what types of GitHub events are tracked.
Tell me which columns would be most useful for finding trending AI and ML repositories
by star activity.
```

**Checkpoint:** CoCo works out that `WatchEvent` means "a repo was starred," and points you at `REPO_NAME`, `CREATED_AT`, and `EVENT_TYPE`.

That inference is the point. Nothing in the schema says "star." CoCo read the data and figured it out.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 1

### 3b. Build the trending repos view

```
Using GITTREND_DB.PUBLIC.GITHUB_EVENTS:

Create a view called GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS that finds repos
that gained the most stars in the last 30 days. The data in this table only
goes through June 18, 2026 — use that as the end of the 30-day window, not
CURRENT_TIMESTAMP.

Where the repo name suggests AI, ML, LLM, GPT, agent, MCP, or open source (names containing "open").
Include exactly these columns, with these names: repo_name, description (use the
repo name for this too), stars_gained, first_star_at, last_star_at.
Only include repos with 10 or more stars gained.

Then query the view to show the top 20 repos by stars gained, descending.
```

**The moment:** look at what's at the top of your list. That's 107M real GitHub events surfacing what the developer community was actually building — signal from the archive, not a model's training memory.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 2

---

# Step 4 — Add Intelligence

**⏱ ~10 min**

### 4a. Wrap the results in `AI_COMPLETE`

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

> **Use `AI_COMPLETE`, not `CORTEX.COMPLETE`.** `CORTEX.COMPLETE` is deprecated and being retired in 2026. `AI_COMPLETE` is the function going forward.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 3

### 4b. Create the Cortex Search Service

```
Create a Cortex Search Service called GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
using the V_TRENDING_AI_REPOS view we just created.

Search on the description column. Include repo_name and stars_gained as attributes.
Use WORKSHOP_WH and a target lag of 1 hour.
```

Takes about 30 seconds. Fire it and move to Step 5 — they overlap.

**Checkpoint:** `SHOW CORTEX SEARCH SERVICES IN SCHEMA GITTREND_DB.PUBLIC` returns `GITHUB_REPO_SEARCH` with status `ACTIVE`.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 4

---

# Step 5 — Wire the Agent

**⏱ ~15 min**

### 5a. Create the Cortex Agent

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

> **On model selection:** use `auto`, not a specific model name. Snowflake picks the best model available for your account and region, and it improves as new models ship. You never have to update the agent config when something better lands.

**Checkpoint:** `SHOW AGENTS IN SCHEMA GITTREND_DB.PUBLIC` returns `GITTREND`.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 5

### 5b. Run it

Open GitTrend in Snowflake CoWork:

**Left nav → AI & ML → Agents → `GITTREND` → Preview → Preview in Snowflake CoWork**

Ask it:

> *"What's the fastest-growing AI project in the last 30 days?"*

Wait for the answer. That answer is grounded in 107M real GitHub events, in an account that was empty when you sat down.

> **Note on the data window:** the archive snapshot runs May 19 – June 18, 2026, so "last 30 days" means that window, not today. You told the agent this in 5a, so it should say so itself. Worth knowing before you ask it what's trending "this month."

Keep going — notice it holds context across turns, so you don't have to re-explain the previous question:

```
What programming languages dominate trending AI repos right now?

Is there anything blowing up around MCP or agentic AI this month?

Compare the top 5 repos — what do they have in common?

Are there any surprise breakouts — repos nobody knows yet but are gaining fast?

Show me a bar chart of the top 10 repos by stars gained.
```

> **That last one triggers Data to Chart.** GitTrend renders a visualization inline. That's the `data_to_chart` tool you added in 5a — the agent decided on its own when to use it.

> **The memory across turns** is Cortex Agent Threads. The agent keeps conversation context, so follow-ups work naturally.

---

## What You Built

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  —  107M real GitHub events loaded from S3
V_TRENDING_AI_REPOS               —  trending AI repo view by star activity
GITHUB_REPO_SEARCH                —  Cortex Search index
GITTREND                          —  Cortex Agent: search + chart + system prompt
```

CoCo wrote every SQL statement. You directed it.

**Now do it on your own data.** Replace `GITHUB_EVENTS` with your support tickets, sales pipeline, product telemetry, or internal docs. Same five steps, same prompts, different schema. That's the part worth taking to work on Monday.

---

# Stretch Step — Expose GitTrend via MCP

**Take-home.** Your trial account stays active after the session, so you can finish this at home.

> **What's the Snowflake-managed MCP Server?**
> An MCP (Model Context Protocol) Server is a Snowflake object that exposes your agents, search services, and analysts to any MCP-compatible client — Claude Desktop, Cursor, VS Code, or your own app. No separate infrastructure, no Docker. A DDL object and a URL. You create it; clients connect and discover your tools automatically.

### S1 — Create the MCP Server

```
Create an MCP Server called GITTREND_DB.PUBLIC.GITTREND_MCP that exposes
the GITTREND agent (GITTREND_DB.PUBLIC.GITTREND) as a tool.

Tool name: "gittrend"
Tool type: CORTEX_AGENT_RUN
Title: "GitTrend — GitHub Trend Analyst"
Description: "GitHub trend analyst with 30 days of real star activity data.
Ask it about trending repos, emerging AI/ML projects, and developer momentum."
```

CoCo generates:

```sql
CREATE OR REPLACE MCP SERVER GITTREND_DB.PUBLIC.GITTREND_MCP
  FROM SPECIFICATION $$
    tools:
      - name: "gittrend"
        type: "CORTEX_AGENT_RUN"
        identifier: "GITTREND_DB.PUBLIC.GITTREND"
        title: "GitTrend — GitHub Trend Analyst"
        description: >
          GitHub trend analyst with 30 days of real star activity data.
          Ask it about trending repos, emerging AI/ML projects, and developer momentum.
  $$;
```

Verify: `SHOW MCP SERVERS IN SCHEMA GITTREND_DB.PUBLIC;`

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 6

### S2 — Set up OAuth

MCP clients authenticate via OAuth. The redirect URI below is for **claude.ai (web)**. Claude Desktop and Cursor each show their own redirect URI during setup — use theirs instead.

```sql
CREATE OR REPLACE SECURITY INTEGRATION GITTREND_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback';
```

Get your client ID and secret:
```sql
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('GITTREND_MCP_OAUTH');
```

Save the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` — you need them when you connect a client below.

MCP OAuth sessions require a default role and warehouse on your user:
```sql
SET MY_USER = CURRENT_USER();
ALTER USER IDENTIFIER($MY_USER) SET DEFAULT_ROLE = 'ACCOUNTADMIN' DEFAULT_WAREHOUSE = 'WORKSHOP_WH';
```

### S3 — Connect a client

Your MCP Server URL:
```
https://<your-account-url>/api/v2/databases/GITTREND_DB/schemas/PUBLIC/mcp-servers/GITTREND_MCP
```

> **Finding your account URL:** it's `https://<orgname>-<accountname>.snowflakecomputing.com`, from Admin → Accounts in Snowsight. Use **hyphens** in the hostname, never underscores — underscores cause MCP connection failures in several clients.

**Easiest path — CoCo Desktop.** It discovers MCP Servers in your account automatically and skips OAuth entirely, because it's already authenticated through your Snowflake connection. Open CoCo Desktop, connect to the same account, and GitTrend appears in your tools.

**claude.ai (web):**
1. claude.ai → Settings → Connectors → **Add custom connector**
2. Name: `GitTrend` | URL: your MCP Server URL
3. Enter the client ID and secret from S2
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

Now ask GitTrend the same questions from inside your editor. Same agent, different front door.

---

## Take It Further

**Add Cortex Analyst via a Semantic View.** Build a Semantic View over your data and add it as a `CORTEX_ANALYST_MESSAGE` tool. Your clients can then ask structured analytical questions alongside conversational search. Agents generate SQL directly from semantic views — faster and more accurate than the older two-step approach.

**Add MCP Connectors (outbound).** You built an MCP Server, which is inbound. MCP Connectors are the opposite direction — your agent calling *out* to Jira, Salesforce, GitHub's own MCP server, or your APIs. Same protocol, opposite flow. Picture asking GitTrend: *"Open a Jira ticket for the top trending repo we should evaluate."*

**Add an Agent Skill.** Skills are modular instruction sets (`SKILL.md` files) that teach your agent new behaviors without touching its core spec. Upload one to a stage, attach it, and the agent follows that playbook when relevant questions come in — no redeployment. See [`sample_weekly_digest_skill.md`](sample_weekly_digest_skill.md) and the [Agent Skills docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-skills).

**Add a SQL execution tool.** Add `SYSTEM_EXECUTE_SQL` to your MCP Server and any client can run ad-hoc queries against your account. Useful for power users who want raw access next to the agent.

---

## Resources

- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)
