# Workshop Guide
## Build an AI Agent in 60 Minutes with Snowflake CoCo
**TechEquity AI Forum — June 30, 2026 | 7:00–8:15 PM | Workshop Room**
**Facilitated by Richie Bachala, Snowflake**

---

## Step 0 — Account Setup (First 10 minutes of session)

We do this together at the start. **Bring your laptop — no prep needed.**

### 1. Create a free Snowflake trial account
Use this event-specific link — it enables all AI features automatically:
**[Sign up here](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)**
Choose **AWS US East** when prompted. Select **AI Data Cloud** as your use case.

> Takes ~2 minutes. While yours activates, the data load below can run in parallel.

### 2. Load the GitHub Archive dataset
In Snowsight, open a new SQL Worksheet and run this block — it creates your database, loads ~107M real GitHub events from a public S3 bucket, and enables Cortex AI. **Runs in ~4 minutes on the Small warehouse.**

```sql
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GITTREND_DB;
CREATE SCHEMA IF NOT EXISTS GITTREND_DB.PUBLIC;
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WAREHOUSE_SIZE = SMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE WORKSHOP_WH;
-- Enable Cortex AI cross-region (required for CORTEX.COMPLETE)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Load GitHub Archive data from public S3 (~4 min)
CREATE OR REPLACE FILE FORMAT GITHUB_JSON_FORMAT
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE
  COMPRESSION = 'GZIP';

CREATE OR REPLACE STAGE GITHUB_STAGE
  URL = 's3://sfquickstarts/vhol_building_ai_agents_with_coco/'
  FILE_FORMAT = GITHUB_JSON_FORMAT;

CREATE OR REPLACE TABLE GITTREND_DB.PUBLIC.GITHUB_EVENTS (
    RAW          VARIANT,
    EVENT_ID     STRING,
    EVENT_TYPE   STRING,
    CREATED_AT   TIMESTAMP,
    ACTOR_LOGIN  STRING,
    ACTOR_ID     NUMBER,
    REPO_NAME    STRING,
    REPO_ID      NUMBER,
    ORG_LOGIN    STRING,
    IS_PUBLIC    BOOLEAN
);

COPY INTO GITTREND_DB.PUBLIC.GITHUB_EVENTS
FROM (
    SELECT
        $1,
        $1:id::STRING,
        $1:type::STRING,
        $1:created_at::TIMESTAMP,
        $1:actor:login::STRING,
        $1:actor:id::NUMBER,
        $1:repo:name::STRING,
        $1:repo:id::NUMBER,
        $1:org:login::STRING,
        $1:public::BOOLEAN
    FROM @GITHUB_STAGE
)
PATTERN = '.*json.gz';

-- Verify (~107M rows expected)
SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS;
```

> **While the data loads (~4 min):** listen to the intro slides. The load runs in the background — you'll be ready for Step 1 by the time we get there.

### 3. Verify CoCo is available
In Snowsight, select the **Cortex Code icon** in the lower-right corner. The CoCo panel opens on the right side.
If you don't see it, confirm your role has `SNOWFLAKE.COPILOT_USER` and `SNOWFLAKE.CORTEX_USER` granted (trial accounts created via the workshop link should have this by default).

---

## Tonight's Goal

By the end of this session you will have built **GitTrend** — a working AI agent that answers questions like:

- *"What's the fastest-growing AI project this month?"*
- *"What languages dominate trending repos right now?"*
- *"Is there anything blowing up in agentic AI this week?"*

It runs against 107M+ real GitHub events. You built it. You own it.

---

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  your data (107M real GitHub events)
CoCo                               →  writes the code
CORTEX.COMPLETE                    →  turns SQL results into language
CORTEX.SEARCH                      →  semantic search over repo names
Cortex Agent (GitTrend)            →  wires it all together
CoWork                             →  where you ask it questions
```

---

## Step 1 — Orient CoCo to Your Data
**⏱ 5–10 min**

Open CoCo by selecting the Cortex Code icon in the lower-right corner of Snowsight. You'll see a chat panel on the right — this is your AI coding partner for the session. It already knows your account, your databases, and your schemas.

### Your first prompt

Paste this into CoCo exactly:

```
I have a table called GITTREND_DB.PUBLIC.GITHUB_EVENTS loaded from the GitHub Archive.
Explore it: describe the key columns,
and explain what types of GitHub events are tracked.
Tell me which columns would be most useful for finding
trending AI and ML repositories by star activity.
```

**What CoCo does:**
- Runs `DESCRIBE TABLE` and samples rows to understand the shape of the data
- Explains the `EVENT_TYPE` column values (WatchEvent = star, PushEvent = commit, etc.)
- Recommends which columns to use for trending analysis (`EVENT_TYPE`, `REPO_NAME`, `CREATED_AT`)

> **Checkpoint 1:** CoCo should identify that `WatchEvent` records a user starring a repo and point you to `REPO_NAME`, `CREATED_AT`, and `EVENT_TYPE` as the key columns.
>
> If CoCo gets stuck, run the SQL in `CHECKPOINTS.sql` → **Checkpoint 1** manually.

---

## Step 2 — Build the Trending Repos Query
**⏱ 10–25 min**

Now tell CoCo what you want to find.

### Prompt

```
Using the GITTREND_DB.PUBLIC.GITHUB_EVENTS table:

Create a view called GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS that finds
repositories that gained the most stars in the last 30 days,
where the repo name suggests AI, ML, LLM, agent,
or open source (e.g. names containing "open").

Include: repo name, stars gained, first and last star timestamps.
Only include repos with 10 or more stars gained.

Then query the view to show the top 20 repos by stars gained, descending.
```

**What CoCo generates:**
A `CREATE OR REPLACE VIEW` filtering `EVENT_TYPE = 'WatchEvent'`, grouping by `REPO_NAME`, and aggregating star counts — followed by a `SELECT` querying the view for the top 20 results.

> **Note:** The dataset covers a fixed 30-day window loaded at setup time. All date filters use `-30 days` to stay within that window. The `description` field is not available in this dataset — repo names are used as the searchable identifier.

### Run it

Click **Run** in the CoCo output or paste the SQL into a new worksheet.

> **Checkpoint 2:** The view is created and the top 20 repos appear — real repo names, real star counts from the last 30 days.
>
> **The moment:** Say the name at the top of your list out loud. That's the real signal of what the developer community is building right now — not a prediction, not a model's training data, the actual activity from the last 30 days.
>
> **Bonus:** If you see **OpenClaw** in the results — that's the project from Dave Nielsen's 3:30 workshop. Your agent just discovered it independently from real GitHub star data. That's not a coincidence. That's signal.

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

`CORTEX.COMPLETE` summarizes. `CORTEX.SEARCH` finds. Now give your agent the ability to semantically search across repo names.

### Prompt

```
Create a Cortex Search Service called GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
using the V_TRENDING_AI_REPOS view we just created.

It should search on the description column and include repo_name
and stars_gained as attributes.

If description is absent, use repo_name as description.

Use WORKSHOP_WH as the warehouse and a target lag of 1 hour.
```

**What CoCo generates:**

```sql
CREATE OR REPLACE CORTEX SEARCH SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    ON description
    ATTRIBUTES repo_name, stars_gained
    WAREHOUSE = WORKSHOP_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT repo_name, description, stars_gained
    FROM V_TRENDING_AI_REPOS
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
2. Uses claude-sonnet-4-5 as the orchestration model
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
CREATE OR REPLACE AGENT GITTREND_DB.PUBLIC.GITTREND
  COMMENT = 'GitHub trend analyst — 30 days of star activity'
  FROM SPECIFICATION
$$
models:
  orchestration: "claude-sonnet-4-5"

instructions:
  system: >
    You are GitTrend, a GitHub trend analyst with access to 30 days of real
    GitHub star activity data from the GitHub Archive. You help users discover
    trending repositories, emerging technologies, and developer community activity
    in AI, ML, open source tooling, and software engineering.
    Always cite which specific repositories you are drawing from when making claims.
    When presenting results, include star counts and organization names where available.
  response: >
    Be concise and data-driven. Use bullet points for lists of repositories.
    Always mention the repo name in owner/repo format and the star count when referencing data.

tools:
  - tool_spec:
      type: "cortex_search"
      name: "github_repo_search"
      description: "Search GitHub repositories by semantic meaning. Use this to find repos related to a topic, technology, or use case based on their names, organizations, and activity patterns."

tool_resources:
  github_repo_search:
    name: "GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH"
    max_results: 10
  SaveCodeToStage:
    type: procedure
    name: "GITTREND_DB.PUBLIC.SAVE_CODE_TO_STAGE(VARCHAR, VARCHAR)"
    execution_environment:
      warehouse: WORKSHOP_WH
$$;
```

> **Checkpoint 5:** `SHOW AGENTS` returns `GITTREND`. You're done building.

---

## Run It — Ask GitTrend
**⏱ 55–60 min**

### Option A: CoWork
1. Open **CoWork** from the left nav
2. Find **GitTrend** in your agents list
3. Ask it anything

> **Tip:** If GitTrend doesn't initially appear in CoWork, navigate to **Agents** from the left nav, select the **GITTREND** agent, confirm that **Snowflake CoWork** is enabled in the About/Overview section, then select **Preview in Snowflake CoWork** in the top right.

### Option B: Test directly in SQL

```sql
-- Use CoWork (recommended) or test via the Cortex Agents REST API.
-- In CoWork: left nav → CoWork → find GitTrend → ask your question.
-- To test the search service directly in SQL:
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH',
        '{"query": "fastest growing AI agent framework", "columns": ["repo_name","stars_gained"], "limit": 5}'
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
GITTREND_DB.PUBLIC.GITHUB_EVENTS  —  107M real GitHub events loaded from S3
GITHUB_REPO_SEARCH                —  Cortex Search index on repo names
GITTREND                          —  Cortex Agent: search + complete + system prompt
CoWork interface                  —  Natural language Q&A on real GitHub data
```

CoCo wrote every SQL statement. You directed it.

---

## Take It Further

**Level up with AGENTS.md:**
Create a file called `AGENTS.md` at the root of any project folder. Put your Snowflake account, role, warehouse, schema, and what must not change. CoCo auto-loads it at the start of every session — it becomes your persistent context. Under 200 lines keeps compliance near 100%. 30 minutes of setup improves every future session.

```
# AGENTS.md
Account: myorg-myaccount
Role: ACCOUNTADMIN
Warehouse: WORKSHOP_WH
Database: GITTREND_DB
Schema: GITTREND_DB.PUBLIC

Do NOT modify: production tables, RBAC roles, cost-sensitive resources.
Always use WAREHOUSE = WORKSHOP_WH in DDL.
Always use fully qualified object names (DB.SCHEMA.OBJECT).
```

**Adapt this to your own data:**
The same 5-step pattern works on any dataset in your org.
Replace GH Archive with your product telemetry, support tickets,
sales data, or internal docs.

**Bonus Step — Export Code to Stage:**
Give GitTrend the ability to write generated SQL, reports, or HTML dashboards to a Snowflake internal stage and hand back a presigned download URL.

Run this once (requires Anaconda terms acceptance on trial accounts — **Admin → Snowflake Marketplace → Anaconda**):

```sql
-- Stage the agent will write to
CREATE STAGE IF NOT EXISTS GITTREND_DB.PUBLIC.CODE_STAGE
  DIRECTORY = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Stored procedure: writes any text file to the stage
CREATE OR REPLACE PROCEDURE GITTREND_DB.PUBLIC.SAVE_CODE_TO_STAGE(
    FILE_NAME STRING,
    CODE STRING
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
import io

def run(session, file_name, code):
    stage_path = "@GITTREND_DB.PUBLIC.CODE_STAGE"
    session.file.put_stream(
        io.BytesIO(code.encode('utf-8')),
        f"{stage_path}/{file_name}",
        auto_compress=False,
        overwrite=True
    )
    return f"Saved {file_name} to {stage_path}"
$$;
```

Then recreate GitTrend with the export tool added — paste this into CoCo:

```
Update GITTREND to add a tool called SaveCodeToStage backed by the stored
procedure GITTREND_DB.PUBLIC.SAVE_CODE_TO_STAGE(VARCHAR, VARCHAR).
The tool should write any generated code or text to @GITTREND_DB.PUBLIC.CODE_STAGE
when the user asks to save, export, or download a file.
Use WORKSHOP_WH as the execution warehouse.
```

Then ask it:
```
Generate an HTML dashboard of the top 10 trending AI repos with star counts
and save it to the stage. Give me the presigned URL to download it.
```

**Resources:**
- [Free Snowflake trial](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)
- [CoCo documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Build an End-to-End App with CoCo](https://www.snowflake.com/en/developers/guides/sfguide-build-end-to-end-ai-app-on-snowflake/)
- [Getting Started with Snowflake CoWork](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-cowork)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

*Built at TechEquity AI Forum | June 30, 2026 | Snowflake SVAI Hub, Menlo Park*
