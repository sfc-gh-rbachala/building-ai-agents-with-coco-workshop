# Building AI Agents with Snowflake CoCo

**TechEquity AI Forum — June 30, 2026 | 7:00 PM | Snowflake SVAI Hub, Menlo Park**

Workshop materials for *Build an AI Agent in 60 Minutes with Snowflake CoCo*, presented by [Richie Bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/), Solutions Architecture Leader at Snowflake.

![Workshop demo — 5-step CoCo build](TechEquity-Workshop-Demo.gif)

---

## What You'll Build

**GitTrend** — a working Cortex AI agent that answers natural language questions about trending GitHub repositories, powered by 107M+ real GitHub events (30 days of public GitHub activity).

![GitTrend answering questions in CoWork](gittrend-showcase.gif)

Ask it things like:
- *"What's the fastest-growing AI project in the last 30 days?"*
- *"What languages dominate trending repos right now?"*
- *"Is there anything trending around agentic AI or MCP this month?"*

CoCo writes every SQL statement. You direct it. You own the result.

---

## Before You Arrive (Do This First)

Complete these steps **before June 30** so we can skip setup during the session.

### 1. Create a free Snowflake trial account
Use the event-specific link below — it enables all AI features for the workshop:
**[Sign up here](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)**
Choose **AWS US East** when prompted. Select **AI Data Cloud** as your use case.

### 2. Load the GitHub Archive dataset
Open a new SQL Worksheet in Snowsight and run the full setup block below. It creates your database and loads ~107M real GitHub events from a public S3 bucket. **Takes ~7 minutes — start this now.**

```sql
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GITTREND_DB;
CREATE SCHEMA IF NOT EXISTS GITTREND_DB.PUBLIC;
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE WORKSHOP_WH;
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

CREATE OR REPLACE FILE FORMAT GITHUB_JSON_FORMAT
  TYPE = 'JSON' STRIP_OUTER_ARRAY = TRUE COMPRESSION = 'GZIP';

CREATE OR REPLACE STAGE GITHUB_STAGE
  URL = 's3://sfquickstarts/vhol_building_ai_agents_with_coco/'
  FILE_FORMAT = GITHUB_JSON_FORMAT;

CREATE OR REPLACE TABLE GITTREND_DB.PUBLIC.GITHUB_EVENTS (
    RAW VARIANT, EVENT_ID STRING, EVENT_TYPE STRING,
    CREATED_AT TIMESTAMP, ACTOR_LOGIN STRING, ACTOR_ID NUMBER,
    REPO_NAME STRING, REPO_ID NUMBER, ORG_LOGIN STRING, IS_PUBLIC BOOLEAN
);

COPY INTO GITTREND_DB.PUBLIC.GITHUB_EVENTS
FROM (SELECT $1,$1:id::STRING,$1:type::STRING,$1:created_at::TIMESTAMP,
    $1:actor:login::STRING,$1:actor:id::NUMBER,$1:repo:name::STRING,
    $1:repo:id::NUMBER,$1:org:login::STRING,$1:public::BOOLEAN
    FROM @GITHUB_STAGE)
PATTERN = '.*json.gz';

SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS; -- expect ~107M
```

### 3. Verify CoCo is available
In Snowsight, look for **CoCo** in the left nav.
If you don't see it: **Admin → Snowsight Features → Enable CoCo**.

---

## Workshop Files

| File | What it is |
|---|---|
| [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | Step-by-step guide — follow this during the session |
| [`CHECKPOINTS.sql`](CHECKPOINTS.sql) | Fallback SQL for each step — use if CoCo gets stuck |

---

## The 5-Step Pattern

![Workshop teaser — intro to payoff](workshop-teaser.gif)

```
1. Load the data         →  107M GitHub events via COPY INTO from public S3
2. CoCo explores         →  Describe the schema, find the right columns
3. Build the query       →  Trending AI repos by star activity, last 30 days
4. Add CORTEX.COMPLETE   →  Turn SQL results into natural language
5. Wire the agent        →  Cortex Search + Cortex Agent = GitTrend
```

Same pattern works on any dataset in your organization.

---

## Resources

- [Event trial account signup](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)
- [CoCo documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-code)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Build an End-to-End App with CoCo](https://www.snowflake.com/en/developers/guides/sfguide-build-end-to-end-ai-app-on-snowflake/)
- [Getting Started with Snowflake CoWork](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-cowork/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

## About the Presenter

**Richie Bachala** — Solutions Architecture Leader, Snowflake  
[snowflake.com/en/blog/authors/richie-bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/)

---

*TechEquity AI Forum | June 30, 2026 | Snowflake SVAI Hub, 135 Constitution Dr, Menlo Park, CA*
