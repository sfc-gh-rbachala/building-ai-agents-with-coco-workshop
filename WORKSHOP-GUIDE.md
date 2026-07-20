# Workshop Guide
## Foundation to Intelligence Series — Level 2
### Build, Extend, and Expose a Production AI Agent with Snowflake CoCo
**TechEquity AI Forum — July 28, 2026 | 7:00–8:15 PM | Workshop Room**
**Facilitated by Richie Bachala, Snowflake**
**Level: Intermediate / Advanced**

---

## Pre-Work — Do This Before You Arrive

This session runs in the CoCo CLI, not Snowsight. Complete these two things before you get there.

### 1. Install CoCo CLI

**macOS / Linux / WSL:**
```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

This installs the `cortex` executable in `~/.local/bin`. Confirm it works:
```bash
cortex --version
```

### 2. Have a Snowflake account ready
Use this event-specific link — it activates all AI features automatically:
**[signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)**
Choose **AWS US East (Ohio)** when prompted. Select **AI Data Cloud** as your use case.

> If you attended the June forum, your existing trial account works fine. Skip to Step 0.

---

## Tonight's Goal

Build **GitTrend v2** — an MCP-connected AI agent that any tool (Claude Desktop, Cursor, VS Code) can query in plain English, powered by 107M real GitHub events.

The 3:30 session covered how to attack and defend MCP endpoints. This session builds the endpoint. You leave tonight with both halves of the picture.

---

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  107M real GitHub events (from S3)
CoCo CLI                           →  writes the code (your terminal, not Snowsight)
V_TRENDING_AI_REPOS                →  trending AI repos by star activity
AI_COMPLETE                        →  turns SQL results into language
GITHUB_REPO_SEARCH                 →  Cortex Search Service (semantic index)
GITTREND                           →  Cortex Agent (search + complete + system prompt)
GITTREND_MCP                       →  MCP Server (exposes GitTrend to any MCP client)
```

---

## Step 0 — AGENTS.md + CLI Connection
**⏱ First 10 minutes**

This is the foundation. Do this before anything else.

### 1. Create your project folder and AGENTS.md

```bash
mkdir gittrend-workshop && cd gittrend-workshop
```

Create a file called `AGENTS.md` in this folder with your account details:

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

> **Why AGENTS.md matters:** CoCo reads this file at the start of every session. It knows your account, your warehouse, your constraints — without you re-explaining it every time. Under 200 lines keeps compliance near 100%. This file is the reason tonight's workflow is faster than anything you've seen in Snowsight.

### 2. Connect to Snowflake and start CoCo

From inside the `gittrend-workshop/` folder, run:

```bash
cortex
```

On first launch, a setup wizard guides you through creating a Snowflake connection — enter your account identifier, username, and password when prompted.

> **Account identifier format:** `orgname-accountname` (find it in Admin → Accounts in Snowsight). For trial accounts, typically `your-org-name-<random>`.

> **Already have a Snowflake CLI connection?** CoCo shares the same `~/.snowflake/connections.toml`. It will list your existing connections — just select one.

Once connected, CoCo starts and automatically loads your `AGENTS.md`. You'll see a confirmation in the session header.

> **For live demos or exploring production data:** relaunch with `cortex --sql-read-only` to prevent accidental writes. Toggle mid-session with `/sql-writes off`.

> **If your session context gets long:** type `/compact` to summarize the conversation and free up context without losing your place.

> **AGENTS.md not loaded?** Make sure you ran `cortex` from the `gittrend-workshop/` directory where the file lives.

---

## Step 1 — Load the Data
**⏱ 5 min (fires in background)**

In your CoCo terminal, paste this prompt:

```
Run the following setup SQL in my Snowflake account:
- Create GITTREND_DB database and PUBLIC schema
- Create WORKSHOP_WH warehouse (Small size, auto-suspend 60s)
- Enable Cortex AI cross-region
- Create a JSON file format and S3 stage pointing to s3://sfquickstarts/vhol_building_ai_agents_with_coco/
- Create GITHUB_EVENTS table with columns: RAW VARIANT, EVENT_ID, EVENT_TYPE, CREATED_AT, ACTOR_LOGIN, ACTOR_ID, REPO_NAME, REPO_ID, ORG_LOGIN, IS_PUBLIC
- COPY INTO from the stage using pattern .*json.gz
- Run SELECT COUNT(*) to verify (~107M rows expected)
```

CoCo writes and runs the setup SQL. **This takes ~4 minutes.** Move to the next slides immediately — it runs in the background.

> **If CoCo needs confirmation at each step,** use `CHECKPOINTS.sql` → SETUP block and run it in a Snowsight worksheet in parallel. Both paths get you to the same result.

> **Verify:** `SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS` should return ~107,752,158 rows.

---

## Step 2 — Build the GitTrend Agent
**⏱ 15–30 min**

This is a compressed version of the v1 workshop. Intermediate audience: move fast through these. If you built GitTrend in June, this is a 10-minute refresh. If you're new, follow every step — the prompts are self-explanatory.

### 2a — CoCo explores the schema

```
I have a table called GITTREND_DB.PUBLIC.GITHUB_EVENTS loaded from the GitHub Archive.
Explore it: describe the key columns, explain what types of GitHub events are tracked.
Tell me which columns would be most useful for finding trending AI and ML repositories
by star activity.
```

**Checkpoint:** CoCo identifies `WatchEvent` = a repo star, recommends `REPO_NAME`, `CREATED_AT`, `EVENT_TYPE`.
> Stuck? → `CHECKPOINTS.sql` → Checkpoint 1

### 2b — Build the trending repos view

```
Using GITTREND_DB.PUBLIC.GITHUB_EVENTS:

Create a view called GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS that finds repos
that gained the most stars in the last 30 days, where the repo name suggests
AI, ML, LLM, agent, MCP, or open source (names containing "open").

Include: repo name as both repo_name and description, stars gained,
first and last star timestamps.
Only include repos with 10 or more stars gained.

Then query the view to show the top 20 repos by stars gained, descending.
```

**The moment:** Call out the project at the top of your list. That's 107M GitHub events surfacing what the developer community is actually building right now.

> Stuck? → `CHECKPOINTS.sql` → Checkpoint 2

### 2c — Add AI_COMPLETE

```
Take the view we just created. Wrap the results in a call to AI_COMPLETE so
that instead of returning raw rows, it returns a natural language summary.

The summary should:
- Name the top 3 trending AI repos and why they're gaining momentum
- Note any patterns across language, topic, or category
- Be concise — 3 to 4 sentences max

Use the 'claude-sonnet-4-6' model.
```

> **Note:** Use `AI_COMPLETE`, not `CORTEX.COMPLETE`. `CORTEX.COMPLETE` is deprecated and being retired in 2026. `AI_COMPLETE` is the canonical function going forward.

**Checkpoint:** Running the query returns a paragraph, not rows.
> Stuck? → `CHECKPOINTS.sql` → Checkpoint 3

### 2d — Create Cortex Search Service

```
Create a Cortex Search Service called GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
using the V_TRENDING_AI_REPOS view we just created.

Search on the description column. Include repo_name and stars_gained as attributes.
Use WORKSHOP_WH and a target lag of 1 hour.
```

Runs in ~30 seconds. Fire and move to 2e immediately — they overlap.

**Checkpoint:** `SHOW CORTEX SEARCH SERVICES IN SCHEMA GITTREND_DB.PUBLIC` returns `GITHUB_REPO_SEARCH` with status `ACTIVE`.
> Stuck? → `CHECKPOINTS.sql` → Checkpoint 4

### 2e — Create the Cortex Agent

```
Create a Cortex Agent called GITTREND_DB.PUBLIC.GITTREND that:

1. Uses GITHUB_REPO_SEARCH (the Cortex Search service we just built)
   as a search tool for finding relevant repos
2. Uses auto as the orchestration model (Snowflake selects the best available)
3. Includes a data_to_chart tool so it can generate visualizations
4. Has a system prompt that tells it:
   - It is GitTrend, a GitHub trend analyst
   - It has access to 30 days of real GitHub star data
   - It should answer questions about trending repos, emerging technologies,
     and developer community activity
   - It should always cite the specific repos it's drawing from

Create it in GITTREND_DB.PUBLIC.
```

> **Note on model selection:** Use `auto` instead of a specific model name. Snowflake picks the highest-quality model available for your account and region, and it improves automatically as new models ship. You never need to update your agent config when a better model is released.

**Checkpoint:** `SHOW AGENTS IN SCHEMA GITTREND_DB.PUBLIC` returns `GITTREND`.
> Stuck? → `CHECKPOINTS.sql` → Checkpoint 5

---

## Step 3 — Wire the MCP Server
**⏱ 30–50 min**

> **What's the Snowflake-managed MCP Server?**
> An MCP (Model Context Protocol) Server is a Snowflake object that exposes your agents, search services, and analysts to any MCP-compatible client — Claude Desktop, Cursor, VS Code, or your own app. No separate infrastructure. No Docker. Just a DDL object and a URL. You create it; clients connect to it and discover your tools automatically.

This is the new step for v2. Two substeps: create the MCP Server object, then configure OAuth so clients can authenticate.

### 3a — Create the MCP Server

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

> Stuck? → `CHECKPOINTS.sql` → Checkpoint 6

### 3b — Set up OAuth

MCP clients authenticate via OAuth. Run this to create the security integration:

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

> Save the `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` — you'll need them in Step 3c.

Set your user's default role and warehouse (required for MCP OAuth sessions):
```sql
ALTER USER <your_username> SET DEFAULT_ROLE = 'ACCOUNTADMIN' DEFAULT_WAREHOUSE = 'WORKSHOP_WH';
```

> Stuck? → `CHECKPOINTS.sql` → Checkpoint 6 (OAuth block)

### 3c — Connect from Claude Desktop or Cursor

Your MCP Server URL is:
```
https://<your-account-url>/api/v2/databases/GITTREND_DB/schemas/PUBLIC/mcp-servers/GITTREND_MCP
```

> **Important:** Replace any underscores (`_`) in your account URL hostname with hyphens (`-`). Some MCP clients have issues with underscores. For example: `myorg-myaccount.snowflakecomputing.com` — keep hyphens, don't add extra.

**Option A — Claude Desktop:**
1. Open Settings → Connectors
2. Click **Add custom connector**
3. Name: `GitTrend` | URL: your MCP Server URL above
4. Enter client ID and secret from 3b
5. Click Add → authenticate in the browser popup

**Option B — Cursor (`mcp.json`):**

Edit `~/.cursor/mcp.json` and add:
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

Open Cursor Settings → MCP → locate `gittrend` → click **Sign in**.

---

## Run It — Ask GitTrend from Your AI Tool
**⏱ 50–65 min**

Open Claude Desktop (or Cursor). You should see GitTrend in your tools list.

Ask it:

> *"What's the fastest-growing AI project in the last 30 days?"*

Wait. Let the answer come back.

That answer is grounded in 107M real GitHub events. You built the agent. You exposed the endpoint. The 3:30 session showed you how to lock the door. Now you've built what goes behind it.

Try a few more — and notice that GitTrend remembers context across turns. You don't re-explain the prior question:
```
What programming languages dominate trending AI repos right now?

Is there anything blowing up around MCP or agentic AI this month?

Compare the top 5 repos — what do they have in common?

Are there any surprise breakouts — repos nobody knows yet but are gaining fast?

Show me a bar chart of the top 10 repos by stars gained.
```

> **That last one triggers Data to Chart.** GitTrend will generate a visualization inline. This is the `data_to_chart` tool you added in Step 2e — the agent decided on its own when to use it.

> **The memory across turns** is Cortex Agents Threads — the agent maintains conversation context so follow-up questions work naturally, without you re-explaining context each time.

**Fallback — CoWork:**
If MCP client setup isn't complete, open GitTrend in CoWork:
Left nav → AI & ML → Agents → GITTREND → Preview in Snowflake CoWork

---

## What You Built

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  —  107M real GitHub events loaded from S3
V_TRENDING_AI_REPOS               —  Trending AI repo view by star activity
GITHUB_REPO_SEARCH                —  Cortex Search index on repo names
GITTREND                          —  Cortex Agent: search + AI_COMPLETE + system prompt
GITTREND_MCP                      —  MCP Server: exposes GitTrend to any MCP client
```

CoCo wrote every SQL statement. You directed it.

---

## Take It Further

**Add Cortex Analyst via Semantic View:**
Create a Semantic View on top of your data and add it as a `CORTEX_ANALYST_MESSAGE` tool to the MCP Server. Now your MCP clients can ask structured analytical questions ("show me a chart of star velocity by week") alongside the conversational search. Agents now generate SQL directly from semantic views — faster and more accurate than the prior two-step approach.

**Add MCP Connectors (outbound):**
Your GitTrend agent can also *call out* to other MCP servers — Atlassian Jira, Salesforce, GitHub's own MCP server, or your own APIs. You built an MCP Server (inbound). MCP Connectors are the outbound direction — same protocol, opposite flow. Imagine asking GitTrend: "Open a Jira ticket for the top trending repo that we should evaluate."

**Add SQL execution tool:**
Add `SYSTEM_EXECUTE_SQL` to your MCP Server and any MCP client can run ad-hoc queries against your Snowflake account directly. Useful for power users who want raw access alongside the agent.

**Adapt to your own data:**
Same 6-step pattern. Replace GITHUB_EVENTS with your support tickets, sales pipeline, product telemetry, or internal docs. Same CoCo prompts, different schema.

**Resources:**
- [Free Snowflake trial](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)
- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Getting Started with Managed Snowflake MCP Server (quickstart)](https://quickstarts.snowflake.com/)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)

---

*Built at TechEquity AI Forum | July 28, 2026 | Snowflake SVAI Hub, Menlo Park*
