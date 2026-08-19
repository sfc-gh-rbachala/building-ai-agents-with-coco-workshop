# Workshop Guide — v3
## Cost Intelligence: Know What Your Agent Actually Costs

**This is the v3 guide.** It builds on the GitTrend agent from v2 and adds a cost
intelligence layer — so you can understand, measure, and control the cost of the AI
infrastructure you just built.

**Pre-requisite:** v2 complete (GitTrend agent + MCP Server built and working), or
restore the full v2 state from [`CHECKPOINTS.sql`](CHECKPOINTS.sql) Checkpoint 6
before starting Step 4.

New to this workshop? Start with [`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md).
v3 picks up exactly where v2 ends.

See [`VERSION.md`](VERSION.md) for the full level comparison and checkpoint map.

Facilitated by **Richie Bachala**, Snowflake.

---

## The Goal

You built a production AI agent. It answers questions, renders charts, and is
reachable from any MCP client in the world.

Now the real question: *what does it actually cost to run?*

> "Building agents was the story. Operating them at scale is the strategy."

88% of AI pilots never reach production. The primary reason isn't technical — it's
economics. Teams can't measure what their agents cost, can't set limits before
something runs away, and can't justify the infrastructure to the people holding
the budget.

By the end of this session you will:

- See exactly what your AI build costs, broken down by service type
- Set a hard spending limit so a runaway agent can't surprise you
- Ask CoCo about its own cost footprint — and get an optimization recommendation

---

## What v3 Adds

```
SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY  →  AI credit usage by service type
WORKSHOP_AI_MONITOR                       →  Resource monitor — hard ceiling on WORKSHOP_WH
Per User AI Quota                         →  Daily spend limit per user, all AI services
```

The GITTREND agent and MCP Server from v2 are unchanged. You're adding cost
governance on top of what you already built.

---

# Step 0 — Restore Context

**⏱ ~5 min** | Faster than v2 — you've done this before.

If you just finished v2 in the same terminal session, skip straight to Step 1.

If you're starting fresh:

```bash
mkdir gittrend-workshop && cd gittrend-workshop
```

Create `AGENTS.md`:

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

```bash
cortex
```

> **No connections found?** Select **Sync from app.snowflake.com** — pulls your
> connection from your browser session, no manual entry needed.

**Checkpoint:** `Loaded 1 instruction file` appears below the connection panel.

---

# Step 1 — Verify the v2 State

**⏱ ~5 min** | Confirm your agent is live before adding cost governance.

Paste this into CoCo:

```
Check if these objects exist in GITTREND_DB.PUBLIC:
- GITHUB_EVENTS (table)
- V_TRENDING_AI_REPOS (view)
- GITHUB_REPO_SEARCH (Cortex Search Service)
- GITTREND (Cortex Agent)
- GITTREND_MCP (MCP Server)

Show the status of each.
```

**If all five exist:** you're ready for Step 4 — skip Step 2.

**If any are missing:** run the SETUP + CP1–CP6 block from
[`CHECKPOINTS.sql`](CHECKPOINTS.sql) in a Snowsight worksheet to restore the full
v2 state. That takes ~7 minutes. Come back here when GITTREND and GITTREND_MCP are
both active.

**Checkpoint:** CoCo confirms all five objects exist.

---

# Step 2 — Fast Replay (first-time attendees only)

**⏱ ~10 min** | Skip this if your GitTrend agent is already live from v2.

For first-time attendees: five rapid-fire prompts to build the full v2 stack before
the cost steps. Fire them in order.

### ① Explore the schema

```
I have a table GITTREND_DB.PUBLIC.GITHUB_EVENTS loaded from the GitHub Archive
(107M rows). Describe the key columns and tell me what event types exist.
Which columns are most useful for finding trending AI repos by star activity?
```

### ② Build the view

```
Create GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS — repos with the most WatchEvents
(stars) between May 19 and June 18, 2026. Columns: repo_name, description
(use repo_name), stars_gained, first_star_at, last_star_at. Only repos with 10+
stars. Show the top 20 by stars_gained descending.
```

### ③ Add AI_COMPLETE

```
Take V_TRENDING_AI_REPOS. Wrap the top 10 rows in AI_COMPLETE('claude-sonnet-4-6',
...) to return a 3–4 sentence trend summary naming the top 3 repos and why they're
gaining momentum. Show the query and result.
```

### ④ Create Cortex Search

```
Create CORTEX SEARCH SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH on the
description column of V_TRENDING_AI_REPOS. Attributes: repo_name, stars_gained.
Warehouse: WORKSHOP_WH. Target lag: 1 hour.
```

### ⑤ Create the Agent

```
Create Cortex Agent GITTREND_DB.PUBLIC.GITTREND using GITHUB_REPO_SEARCH as
a search tool and data_to_chart as a chart tool. Orchestration: auto.
System prompt: GitHub trend analyst, data covers May 19–June 18 2026 only, cite
repos in owner/repo format with star count, be concise.
```

**Stuck at any point? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) CP1–CP5**

---

# Step 3 — Verify the MCP Endpoint

**⏱ ~3 min** | Carry-forward confirmation before the cost steps.

```
Show me all MCP Servers in GITTREND_DB.PUBLIC.
```

**Checkpoint:** `SHOW MCP SERVERS IN SCHEMA GITTREND_DB.PUBLIC` returns `GITTREND_MCP`.

> MCP not there? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 6 to restore.

---

# Step 4 — Cost Visibility

**⏱ ~10 min** | The moment of truth.

You built something. Now see what it cost.

```
Show me a breakdown of AI credit usage in my Snowflake account over the last
7 days by service type. Use SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY.
Include total credits per service type, ordered by highest usage.
```

**What CoCo does:** queries METERING_HISTORY, groups by `SERVICE_TYPE`, returns the
cost breakdown.

**What you'll see:** service types like `WAREHOUSE_METERING`, `AI_INFERENCE`,
`CORTEX_CODE_CLI`. Each one maps to something you built. The S3 load is
`WAREHOUSE_METERING`. The AI_COMPLETE calls are `AI_INFERENCE`. The CoCo session
itself is `CORTEX_CODE_CLI`.

**Checkpoint:** CoCo returns a result set with service types and credit totals.

> **METERING_HISTORY latency:** this view has ~3 hour propagation lag. If your
> account was just created today, results may be sparse or empty. Use CP7 from
> [`CHECKPOINTS.sql`](CHECKPOINTS.sql) which uses a wider 30-day window as fallback.

> **No rows at all?** Run `USE ROLE ACCOUNTADMIN` first — METERING_HISTORY requires
> the ACCOUNTADMIN role. Your AGENTS.md already sets this, but CoCo may use a
> different role context for account-level views.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 7

---

# Step 5 — Cost Controls

**⏱ ~12 min** | Visibility without control is a dashboard. Control makes it governance.

### Part 1 — Resource Monitor

```
Create a resource monitor called WORKSHOP_AI_MONITOR. Apply it to WORKSHOP_WH.
Credit quota: 10 credits. Frequency: monthly. Notify me at 80% usage and
suspend the warehouse at 100%.
```

**What CoCo does:** generates `CREATE RESOURCE MONITOR` DDL and an
`ALTER WAREHOUSE` to attach it.

**What this means:** if WORKSHOP_WH burns through 10 credits this month, the
warehouse goes offline. Hard ceiling. No runaway agent can surprise you on the
bill.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 8

### Part 2 — Per User AI Quota

Resource Monitors cover warehouse compute. Per User Quotas cover AI services
specifically: CoCo, CoWork, AI Functions, and Cortex Agents. They enforce per-user
daily or monthly AI spending limits across the account.

```
Set up a per-user AI spending limit of 5 credits per day for all users in this
account. This should cover Cortex Agents and AI Functions.
```

CoCo will generate the DDL or guide you to the Snowsight path.

**Snowsight path (always works):**
Snowsight → Admin → Cost Management → Budgets → **+ Budget** → Per User Quota →
5 credits / day → All Users → Services: AI Functions + Cortex Agents → Save

> **Why this matters:** a 5-credit/day per-user limit is the difference between
> giving your whole org access to agents and locking it down to three approved
> power users. Per User Quotas are how you democratize AI access without the CFO
> calling you. Enforcement happens within minutes of creation — no restart needed.

---

# Step 6 — Ask CoCo About the Cost

**⏱ ~10 min** | Close the loop.

You've built the infrastructure. You've measured it. You've put guardrails on it.
Now ask the tool that built it to help you optimize it.

```
What is the most expensive AI service in my Snowflake account over the last
7 days? Show the trend by day as a chart. Then give me a specific recommendation
to reduce the cost of the GITTREND agent we just built.
```

**What CoCo does:**
1. Queries METERING_HISTORY with a daily breakdown
2. Renders a bar chart inline — cost by service type, by day
3. Gives you a specific optimization recommendation for GITTREND

**Common recommendations CoCo gives:**
- Reduce `max_results` on GITHUB_REPO_SEARCH from 10 to 5 (fewer tokens per query)
- Add a response instruction to be concise (shorter output = lower cost)
- Switch from `auto` to a smaller model for simple queries

All of these are real levers you can pull today without changing the agent's behavior.

**Checkpoint:** you see a cost trend chart and a concrete optimization recommendation.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 9

---

# Run It

**⏱ ~8 min** | Let it land.

Ask CoCo:

```
Summarize the total cost of everything we built in this workshop in Snowflake
credits. Include: loading 107M GitHub events from S3, creating the Cortex Search
Service, running the Cortex Agent, and the CoCo session itself. What's the total,
and how does that compare to what this infrastructure would cost to build another way?
```

This is the v3 payoff. An account that started empty now has:

- A live AI agent grounded in 107M real events
- An MCP endpoint reachable from any AI tool in the world
- A cost dashboard showing exactly what it took to build
- A hard ceiling so it can't run away
- A per-user quota so the whole org can use it safely

CoCo built all of it. You directed it.

---

## What You Built

**v2 (carried forward):**
```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  —  107M real GitHub events loaded from S3
V_TRENDING_AI_REPOS               —  trending AI repo view by star activity
GITHUB_REPO_SEARCH                —  Cortex Search index
GITTREND                          —  Cortex Agent: search + chart + system prompt
GITTREND_MCP                      —  MCP Server + OAuth
```

**v3 (new):**
```
WORKSHOP_AI_MONITOR               —  Resource monitor: hard ceiling on WORKSHOP_WH
METERING_HISTORY query            —  AI credit breakdown by service type
Per User Quota                    —  Daily AI spend limit, all users, all AI services
```

---

## Take It Further

**Wire a Snowflake Alert.** Create an Alert that fires when WORKSHOP_WH crosses 80%
of its resource monitor quota — and sends a notification to Slack or email. Your
agent can page you before it becomes a problem.

**Add cost context to the agent.** Edit GITTREND's system prompt to include a budget
line: `"You operate within a 5-credit daily AI budget. Be concise and avoid
unnecessary tool calls."` The agent will aim for efficiency — shorter answers,
fewer search calls per query.

**Build a cost view for your whole AI fleet.** The METERING_HISTORY pattern from
Step 4 works for every agent in your account. Wrap it in a Cortex Analyst Semantic
View and attach it to a second agent — instant cost analytics across your entire
AI infrastructure, queryable in natural language.

**Use model routing.** The GITTREND agent uses `orchestration: auto`. For simple
factual queries, Snowflake routes to a smaller, faster model. For complex multi-step
reasoning, it routes to a larger one. That routing is automatic — but you can
influence it by writing a clearer system prompt about expected query complexity.

**Now do it on your own data.** Replace `GITHUB_EVENTS` with your support tickets,
product telemetry, or internal docs. The METERING_HISTORY cost visibility, resource
monitors, and per-user quotas work identically on any agent you build.

---

## Resources

- [METERING_HISTORY view docs](https://docs.snowflake.com/en/sql-reference/account-usage/metering_history)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Snowflake Budgets](https://docs.snowflake.com/en/user-guide/budgets)
- [Cortex AI credit usage](https://docs.snowflake.com/en/user-guide/cost-understanding-compute-credit#cortex-functions)
- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)
