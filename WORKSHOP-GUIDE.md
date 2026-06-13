# Workshop Guide
## Build an AI Agent in 60 Minutes with Snowflake CoCo
**TechEquity AI Forum — June 30, 2026 | 7:00–8:15 PM | Workshop Room**
**Facilitated by Richie Bachala, Snowflake**

---

## Before You Arrive — Do This First (10 minutes)

Complete these steps **before June 30** so we can skip setup during the session.

### 1. Create a free Snowflake trial account
Go to **snowflake.com/try** → Sign up → Choose AWS US East.
You'll use this account for everything in tonight's workshop.

### 2. Get the GH Archive dataset
Once logged in to Snowflake (Snowsight):
1. Left nav → **Data Products → Marketplace**
2. Search: `GH Archive`
3. Click the listing → **Get**
4. Database name: `GH_ARCHIVE` (keep default)
5. Click **Get** — done. No cost, no import.

### 3. Run the one-time setup SQL
In Snowsight, open a new SQL Worksheet and run this block once:

```sql
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GITTREND_DB;
CREATE SCHEMA IF NOT EXISTS GITTREND_DB.PUBLIC;
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE WORKSHOP_WH;
-- Enable Cortex AI cross-region (required for CORTEX.COMPLETE)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
```

### 4. Verify CoCo is available
In Snowsight, look for **CoCo** in the left nav (the coding agent icon).
If you don't see it, go to **Admin → Snowsight Features** and enable it.

> **Bring your laptop tonight.** This is a hands-on build session.
> If you hit issues during setup, arrive by 6:45 PM and we'll help you get sorted.

---

## Tonight's Goal

By the end of this session you will have built **GitTrend** — a working AI agent that answers questions like:

- *"What's the fastest-growing AI project this month?"*
- *"What languages dominate trending repos right now?"*
- *"Is there anything blowing up in agentic AI this week?"*

It runs against 4 billion+ real GitHub events. You built it. You own it.

---

## The Stack

```
GH Archive (Marketplace)     →  your data
CoCo                         →  writes the code
CORTEX.COMPLETE              →  turns SQL results into language
CORTEX.SEARCH                →  semantic search over repo descriptions
Cortex Agent (GitTrend)      →  wires it all together
CoWork                       →  where you ask it questions
```

---

## Step 1 — Orient CoCo to Your Data
**⏱ 5–10 min**

Open CoCo from the left nav in Snowsight. You'll see a chat interface — this is your AI coding partner for the session. It already knows your account, your databases, and your schemas.

### Your first prompt

Paste this into CoCo exactly:

```
I have a database called GH_ARCHIVE mounted from Snowflake Marketplace.
Explore it: list all tables, describe the key columns in each,
and explain what types of GitHub events are tracked.
Tell me which columns would be most useful for finding
trending AI and ML repositories by star activity.
```

**What CoCo does:**
- Runs `SHOW TABLES` and `DESCRIBE TABLE`
- Samples rows to understand the shape of the data
- Explains the `type` column values (WatchEvent = star, PushEvent = commit, etc.)
- Recommends which columns to use for trending analysis

> **Checkpoint 1:** CoCo should identify the `EVENTS` table and explain that `WatchEvent` records a user starring a repo. It should point you to `repo:name`, `created_at`, and `type` as the key columns.
>
> If CoCo gets stuck, run the SQL in `CHECKPOINTS.sql` → **Checkpoint 1** manually.

---

## Step 2 — Build the Trending Repos Query
**⏱ 10–25 min**

Now tell CoCo what you want to find.

### Prompt

```
Using the GH_ARCHIVE.PUBLIC.EVENTS table:

Write a SQL query that finds the top 20 repositories
that gained the most stars in the last 30 days,
where the repo name or description suggests AI, ML,
LLM, agent, or open source tooling.

Include: repo name, stars gained, primary language
(if available), and a short description (if available).

Order by stars gained descending.
```

**What CoCo generates:**
A query filtering `type = 'WatchEvent'`, grouping by repo, and aggregating star counts over the date range. It handles the semi-structured JSON columns (`repo:name::string`) automatically.

### Run it

Click **Run** in the CoCo output or paste the SQL into a new worksheet. You should see a real table of the hottest AI repos right now.

> **Checkpoint 2:** You have a result set with 20 rows — real repo names, real star counts from the last 30 days.
>
> **Bonus:** Is OpenClaw in the results? (It should be — it's the fastest-growing open source project on GitHub right now.) If so, you're looking at the same dataset that's shaping the entire AI developer community.

---

## Step 3 — Add CORTEX.COMPLETE
**⏱ 25–35 min**

You have a table of results. Now make it speak.

### Prompt

```
Take the query we just built. Wrap the results in a call to
CORTEX.COMPLETE so that instead of returning raw rows,
it returns a natural language summary.

The summary should:
- Name the top 3 trending AI repos and why they're gaining momentum
- Note any patterns across language, topic, or category
- Be concise — 3 to 4 sentences max

Use the 'claude-4-sonnet' model.
```

**What CoCo generates:**
A SQL statement that passes your query results as context into `SNOWFLAKE.CORTEX.COMPLETE()` with a structured prompt. The exact SQL will reference the view CoCo just created. Here's the shape of what it produces:

```sql
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'claude-4-sonnet',
    CONCAT(
        'You are a developer trend analyst. Based on this GitHub star data, ',
        'summarize the top trending AI/ML repositories in 3-4 sentences. ',
        'Focus on what is gaining momentum and why. Data: ',
        (SELECT LISTAGG(repo_name || ' (' || stars_gained || ' stars)', ', ')
         WITHIN GROUP (ORDER BY stars_gained DESC)
         FROM V_TRENDING_AI_REPOS LIMIT 10)
    )
) AS trend_summary;
```

> If CoCo generates slightly different SQL, that's fine — the pattern is what matters.
> If you need the exact working version, use **Checkpoint 3** in `CHECKPOINTS.sql`.

> **Checkpoint 3:** Running the query returns a paragraph — not rows — describing what's trending in AI on GitHub right now. No hallucination. Every claim is backed by the data you queried.

---

## Step 4 — Create a Cortex Search Service
**⏱ 35–45 min**

`CORTEX.COMPLETE` summarizes. `CORTEX.SEARCH` finds. Now give your agent the ability to semantically search across repo descriptions.

### Prompt

```
Create a Cortex Search Service called GITHUB_REPO_SEARCH
using the GH_ARCHIVE data.

It should index the repo descriptions and names
so users can search semantically — for example,
"find repos related to autonomous agents" or
"what projects are working on RAG pipelines".

Use WORKSHOP_WH as the warehouse.
```

**What CoCo generates:**

```sql
CREATE OR REPLACE CORTEX SEARCH SERVICE GITHUB_REPO_SEARCH
  ON description
  ATTRIBUTES repo_name, stars_gained
  WAREHOUSE = WORKSHOP_WH
  TARGET LAG = '1 hour'
AS (
  SELECT
      repo:name::string                                AS repo_name,
      COALESCE(repo:description::string, repo:name::string) AS description,
      COUNT(*)                                         AS stars_gained
  FROM GH_ARCHIVE.PUBLIC.EVENTS
  WHERE type = 'WatchEvent'
    AND created_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
  GROUP BY repo_name, description
  HAVING COUNT(*) >= 5
);
```

Run this. It takes ~30 seconds to build the index. While it runs, move to Step 5.

> **Checkpoint 4:** `SHOW CORTEX SEARCH SERVICES` returns `GITHUB_REPO_SEARCH` with status `ACTIVE`.

---

## Step 5 — Wire the Agent
**⏱ 45–55 min**

This is the final step. You're wiring everything together into a named agent called **GitTrend**.

### Prompt

```
Create a Cortex Agent called GITTREND that:

1. Uses GITHUB_REPO_SEARCH (the Cortex Search service we just built)
   as a search tool for finding relevant repos
2. Uses CORTEX.COMPLETE with claude-4-sonnet to synthesize answers
3. Has a system prompt that tells it:
   - It is a GitHub trend analyst
   - It has access to 30 days of real GitHub star data
   - It should answer questions about trending repos, emerging technologies,
     and developer community activity
   - It should always cite which repos it's drawing from

Create it in the current database and schema.
```

**What CoCo generates:**

```sql
CREATE OR REPLACE CORTEX AGENT GITTREND_DB.PUBLIC.GITTREND
    TOOLS = (
        CORTEX_SEARCH_SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    )
    COMMENT = 'GitHub trend analyst — 30 days of star activity'
AS
$$
You are GitTrend, a GitHub trend analyst with access to 30 days of real
GitHub star activity data. You answer questions about trending open source
projects, emerging technologies, and developer community momentum.

When answering:
- Always name specific repositories and their star counts
- Note the primary language and category when relevant
- If asked about a specific topic (e.g., "agentic AI"), search for it specifically
- Be direct — developers want signal, not noise
- Do not make claims that aren't supported by the data
$$;
```

> **Checkpoint 5:** `SHOW CORTEX AGENTS` returns `GITTREND`. You're done building.

---

## Run It — Ask GitTrend
**⏱ 55–60 min**

### Option A: CoWork
1. Open **CoWork** from the left nav
2. Find **GitTrend** in your agents list
3. Ask it anything

### Option B: Test directly in SQL

```sql
-- Use CoWork (recommended) or test via the Cortex Agents REST API.
-- In CoWork: left nav → CoWork → find GitTrend → ask your question.
-- To test the search service directly in SQL:
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH',
        '{"query": "fastest growing AI agent framework", "columns": ["repo_name","description","stars_gained"], "limit": 5}'
    )
) AS results;
```

### Questions to try

```
What's the fastest-growing AI project in the last 30 days?

What programming languages dominate trending AI repos right now?

Is there anything trending around agentic AI or MCP this month?

Compare the top 5 repos — what do they have in common?

Are there any surprise breakouts — repos that aren't well-known
but are gaining stars fast?
```

---

## What You Built

```
GH_ARCHIVE             — 4B+ GitHub events, mounted in 1 click
GITHUB_REPO_SEARCH     — Cortex Search index on repo descriptions
GITTREND               — Cortex Agent: search + complete + system prompt
CoWork interface       — Natural language Q&A on real GitHub data
```

CoCo wrote every SQL statement. You directed it.

---

## Take It Further

**Adapt this to your own data:**
The same 5-step pattern works on any dataset in your org.
Replace GH Archive with your product telemetry, support tickets,
sales data, or internal docs.

**Resources:**
- [Free Snowflake trial](https://snowflake.com/try)
- [CoCo documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-code)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Build an End-to-End App with CoCo](https://www.snowflake.com/en/developers/guides/sfguide-build-end-to-end-ai-app-on-snowflake/)
- [Getting Started with Snowflake CoWork](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-cowork/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

*Built at TechEquity AI Forum | June 30, 2026 | Snowflake SVAI Hub, Menlo Park*
