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

> **This week (Aug 18, 2026):** Snowflake announced Dynamic Model Routing inside
> Cortex AI Gateway — automatically routing simpler tasks to lighter models,
> reserving frontier models for complex reasoning. Up to 3x token efficiency on
> comparable workloads. Sridhar Ramaswamy: *"Usage is an input. The question that
> matters is what a company gets in return."*
>
> That is literally the setup for what we're doing today. The routing handles
> efficiency at the infrastructure layer automatically. But visibility and control
> at the application layer — seeing what your account is actually spending, setting
> guardrails, optimizing your specific agent — is still yours to own.
> Steps 4–6 are the hands-on version of that story.

By the end of this session you will:

- See exactly what your AI build costs, broken down by service type
- Set a hard spending limit so a runaway agent can't surprise you
- Ask CoCo about its own cost footprint — and get an optimization recommendation

---

## What v3 Adds

```
SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY     →  AI + compute credit usage by service type (≈3 hr lag)
CORTEX_AI_FUNCTIONS_USAGE_HISTORY            →  per-user / per-model AI function detail (≈2 min lag)
CORTEX_AGENT_USAGE_HISTORY                   →  per-agent token credit breakdown (≈8 min lag)
WORKSHOP_AI_MONITOR (Resource Monitor)       →  Hard ceiling on warehouse compute spend
Snowflake Budget (AI services)               →  Monthly limit on AI credits (Agents, Functions, CoCo)
Per User AI Quota                            →  Daily per-user AI spending ceiling
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

**If all five exist:** skip Step 2 and go straight to Step 3.

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

> **Agent Identity (GA, July 28, 2026).** GITTREND now has its own tracked identity
> in Snowflake's `ACCESS_HISTORY` view, independent of your user session. Governance
> and security teams can see exactly what it queried, when, and which data it touched
> — without correlating against your personal session logs. The `agents_info` column
> (released Aug 3) surfaces this per run. This is the audit foundation the
> infrastructure security conversation is about: once an agent is acting on behalf of
> users, governance has to extend to the agent's identity, not just the user's.

---

# Step 4 — Cost Visibility

**⏱ ~10 min** | The moment of truth.

You built something. Now see what it cost.

> Snowflake's dynamic model routing is already making efficiency decisions at the
> infrastructure layer — routing simpler queries to lighter models automatically,
> claiming 3x token efficiency on comparable workloads. But those decisions are
> invisible unless you're measuring them. METERING_HISTORY is how you see what's
> actually being consumed in your account.

```
Show me a breakdown of AI credit usage in my Snowflake account over the last 7 days.
Start with a high-level summary using SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY — total credits by service type, ordered by highest usage.
Then show the detail from three views:

CORTEX_AI_FUNCTIONS_USAGE_HISTORY — group by FUNCTION_NAME and MODEL_NAME, sum CREDITS. Join USER_ID to SNOWFLAKE.ACCOUNT_USAGE.USERS to get USER_NAME.
CORTEX_AGENT_USAGE_HISTORY — group by AGENT_NAME and USER_NAME, sum TOKEN_CREDITS and TOKENS
SNOWFLAKE_COWORK_USAGE_HISTORY — group by USER_NAME and AGENT_NAME, sum TOKEN_CREDITS and TOKENS

For each detail view, order by highest spend. Then give me a one-sentence summary of which service type drove the most usage.
```

**What CoCo does:** runs four queries — METERING_HISTORY for the high-level service
type summary, then three detail views for per-user, per-model, per-function breakdown.
Each view has a different latency (see note below).

**What you'll see:**
- **Summary (METERING_HISTORY):** `WAREHOUSE_METERING`, `AI_FUNCTIONS`, `CORTEX_SEARCH` — total credits by billing category
- **Detail (CORTEX_AI_FUNCTIONS_USAGE_HISTORY):** per user, per function, per model — e.g., `YOURNAME | AI_COMPLETE | claude-sonnet-4-6 | 0.0048 credits`. The most actionable view: exactly what your agent called and what it cost.
- **Detail (CORTEX_AGENT_USAGE_HISTORY):** token credits per agent per user (may be empty on new accounts)
- **Detail (SNOWFLAKE_COWORK_USAGE_HISTORY):** CoWork session credits per user (may be empty on new accounts)

> **Two credit types, four views.** In METERING_HISTORY, `WAREHOUSE_METERING` shows
> Platform Credits — the edition-priced compute that powers your warehouse.
> `AI_FUNCTIONS` and `CORTEX_SEARCH` show AI Credits — a separate billing unit
> introduced April 2026, priced at $2.00/credit flat regardless of your Snowflake
> edition. The three detail views break those AI credits down further: which user,
> which function, which model, which agent. This is exactly why Step 5 needs two
> separate guardrails — one for each credit currency.

**Checkpoint:** CoCo returns a result set with service types and credit totals.

> **View latency — good news for trial accounts:** the detail views are much faster
> than METERING_HISTORY. Your AI usage from Steps 0–3 (run 30–60 min ago) will
> already be in `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` and `CORTEX_AGENT_USAGE_HISTORY`
> — even on a brand-new account. The METERING_HISTORY summary (~3 hr lag) may be
> sparse, but the detail views will have data.
>
> Latency reference:
> - `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` — ≈2 min
> - `CORTEX_AGENT_USAGE_HISTORY` — ≈8 min
> - `SNOWFLAKE_COWORK_USAGE_HISTORY` — ≈1 hr
> - `METERING_HISTORY` (summary) — ≈3 hr

> **No rows at all?** Run `USE ROLE ACCOUNTADMIN` first — all ACCOUNT_USAGE views
> require ACCOUNTADMIN.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 7

---

# Step 5 — Cost Controls

**⏱ ~14 min** | Visibility without control is a dashboard. Control makes it governance.

There are two credit currencies in Snowflake now — and they need **separate** guardrails.

> **Compute credits (Platform Credits):** warehouse-metered, edition-priced. Controlled by **Resource Monitors**.
>
> **AI credits:** flat $2.00/credit, edition-independent, cover Cortex Agents, AI Functions, CoWork, and CoCo. Resource Monitors do NOT cover these — they need **Budgets** and **Per User Quotas**.

### Part 1 — Resource Monitor (compute ceiling)

```
Create a resource monitor called WORKSHOP_AI_MONITOR. Apply it to WORKSHOP_WH.
Credit quota: 10 credits. Frequency: monthly. Notify me at 80% usage and
suspend the warehouse at 100%.
```

**What CoCo does:** generates `CREATE RESOURCE MONITOR` DDL and `ALTER WAREHOUSE`
to attach it.

**What this covers:** the warehouse compute portion of what you built — the S3 data
load, the Cortex Search refresh, any queries that hit `WORKSHOP_WH` directly.
It does *not* cover AI inference credits.

> Stuck? → [`CHECKPOINTS.sql`](CHECKPOINTS.sql) → Checkpoint 8

### Part 2 — Snowflake Budget (AI cost ceiling)

This is the correct primitive for AI spend. Budgets set monthly credit limits on
AI service types and fire notifications — or execute a stored procedure — when
thresholds are crossed.

```
Set up a monthly AI budget for this account. Limit: 20 AI credits per month.
Cover: AI Functions and Cortex Agents. Notify at 80%.
```

**Snowsight path (always works):**
Admin → Cost Management → Budgets → **+ Budget** →
Set limit: 20 credits / month → Service types: AI Functions + Cortex Agents →
Notification: 80% → Save

> **What makes Budgets powerful:** when a threshold is crossed you can attach a
> Custom Action — a stored procedure that fires automatically. Revoke access,
> write an audit log, post to Slack. The enforcement is programmable, not just
> passive alerts.

### Part 3 — Per User AI Quota (per-user enforcement)

Budgets track aggregate account-level spend. Per User Quotas add a per-user ceiling
so no single person can blow the budget — covering CoCo, CoWork, AI Functions, and
Cortex Agents with a daily or monthly reset.

```
Set up a per-user AI spending limit of 5 credits per day for all users in this
account. This should cover Cortex Agents and AI Functions.
```

CoCo will generate the DDL or guide you to the Snowsight path.

**Snowsight path (always works):**
Admin → Cost Management → Budgets → **+ Budget** → Per User Quota →
5 credits / day → All Users → Services: AI Functions + Cortex Agents → Save

> **Why this matters:** a 5-credit/day per-user limit is the difference between
> giving your whole org access to agents and locking it down to three approved
> power users. Per User Quotas are how you democratize AI access without the CFO
> calling you. Enforcement is automatic within minutes of creation — no restart
> needed, no per-user configuration.

---

# Step 6 — Ask CoCo About the Cost

**⏱ ~10 min** | Close the loop.

You've built the infrastructure. You've measured it. You've put guardrails on it.
Now ask the tool that built it to help you optimize it.

```
Use the Cost Intelligence skill. Why did AI spending occur in my account
this week? Break it down by service type and show a daily trend as a chart.
Then give me a specific recommendation to reduce the cost of the GITTREND
agent we just built — I want to keep it under 2 AI credits per day.
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

> Dynamic model routing is Snowflake doing this automatically at the infrastructure
> layer — switching to lighter models for simpler tasks, 3x more efficient on
> comparable workloads. The recommendations CoCo gives you here are the application-
> layer version of that same principle: match task complexity to the right cost.
> Understanding your own levers matters regardless of what the infrastructure
> already optimizes for you.

**Checkpoint:** you see a cost trend chart and a concrete optimization recommendation.

> **Cost Intelligence skill:** This is CoCo's built-in GA feature for cost analysis.
> You don't invoke it with a slash command — just type the prompt naturally and CoCo
> activates it automatically when it recognizes a cost question. The skill connects
> the dots between ACCOUNT_USAGE, warehouse activity, and user behavior in seconds.

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
WORKSHOP_AI_MONITOR               —  Resource monitor: ceiling on WORKSHOP_WH compute credits
Snowflake Budget (AI)             —  Monthly AI credit limit (Agents, Functions, CoCo)
Per User Quota                    —  Daily per-user AI spending ceiling
Multi-view cost breakdown         —  METERING_HISTORY + 3 detail views (per-user, per-model, per-agent)
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

**Explore Cortex AI Gateway.** Per User Quotas and Budgets are the enforcement
primitives inside your Snowflake account. Cortex AI Gateway (announced July 28, 2026,
built on Snowflake's Natoma acquisition) is the governance layer above that —
centralized control over which agents access which MCP servers, models, and tools;
intelligent routing to cheaper models for simpler tasks; and a full audit trail of
every agent tool call across your fleet. It covers both Snowflake-native agents
(CoCo, CoWork, Cortex Agents) and third-party agents (LangChain, LlamaIndex, Bedrock,
Azure AI Foundry). The next step after per-user quotas.

**Now do it on your own data.** Replace `GITHUB_EVENTS` with your support tickets,
product telemetry, or internal docs. The METERING_HISTORY cost visibility, resource
monitors, and per-user quotas work identically on any agent you build.

---

## Resources

- [METERING_HISTORY view docs](https://docs.snowflake.com/en/sql-reference/account-usage/metering_history)
- [AI cost management and governance](https://docs.snowflake.com/en/user-guide/snowflake-cortex/governance-and-availability/ai-cost-management-and-governance)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Snowflake Budgets](https://docs.snowflake.com/en/user-guide/budgets)
- [Cortex AI credit usage](https://docs.snowflake.com/en/user-guide/cost-understanding-compute-credit#cortex-functions)
- [FinOps for AI: Snowflake's cost management tools (blog)](https://www.snowflake.com/en/blog/ai-finops-cost-management-governance-snowflake/)
- [Cortex AI Gateway announcement (Black Hat 2026)](https://www.snowflake.com/en/blog/enterprise-ai-security-agentic-mcp-governance/)
- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)
