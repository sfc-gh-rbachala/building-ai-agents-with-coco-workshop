-- ============================================================
-- GITTREND WORKSHOP CHECKPOINTS
-- TechEquity AI Forum | June 30, 2026
-- Use these if CoCo gets stuck or you fall behind.
-- Run each checkpoint in a Snowflake SQL Worksheet.
-- ============================================================

-- SETUP (run once at the start)
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GITTREND_DB;
CREATE SCHEMA IF NOT EXISTS GITTREND_DB.PUBLIC;
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WAREHOUSE_SIZE = SMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE WORKSHOP_WH;
-- Required for CORTEX.COMPLETE (run this now, not later)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Load GH Archive data from public S3 (~4 min on Small warehouse)
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

-- Verify row count (~107M expected)
SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS;


-- ============================================================
-- CHECKPOINT 1 — Explore the GITHUB_EVENTS schema
-- ============================================================
-- Understand the table structure and what WatchEvent means

DESCRIBE TABLE GITTREND_DB.PUBLIC.GITHUB_EVENTS;

-- Sample 5 rows to see the structure
SELECT * FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS LIMIT 5;

-- See all the event types available
SELECT EVENT_TYPE, COUNT(*) AS event_count
FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS
WHERE CREATED_AT >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY EVENT_TYPE
ORDER BY event_count DESC;

-- Preview star events (WatchEvent = someone starred a repo)
-- NOTE: RAW:repo:description is not present in this dataset; repo_description will be NULL
SELECT
    EVENT_TYPE,
    REPO_NAME,
    RAW:repo:description::string   AS repo_description,  -- will be NULL
    ACTOR_LOGIN                    AS starred_by,
    CREATED_AT
FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS
WHERE EVENT_TYPE = 'WatchEvent'
  AND CREATED_AT >= DATEADD('day', -30, CURRENT_TIMESTAMP())
LIMIT 20;


-- ============================================================
-- CHECKPOINT 2 — Trending AI repos by stars (last 30 days)
-- ============================================================

CREATE OR REPLACE VIEW GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS AS
SELECT
    REPO_NAME          AS repo_name,
    REPO_NAME          AS description,   -- description field not in dataset; using repo_name
    COUNT(*)           AS stars_gained,
    MIN(CREATED_AT)    AS first_star_at,
    MAX(CREATED_AT)    AS last_star_at
FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS
WHERE EVENT_TYPE = 'WatchEvent'
  AND CREATED_AT >= DATEADD('day', -30, CURRENT_TIMESTAMP())
  AND (
      LOWER(REPO_NAME) LIKE '%llm%'
   OR LOWER(REPO_NAME) LIKE '%agent%'
   OR LOWER(REPO_NAME) LIKE '%gpt%'
   OR LOWER(REPO_NAME) LIKE '%ai%'
   OR LOWER(REPO_NAME) LIKE '%ml%'
   OR LOWER(REPO_NAME) LIKE '%mcp%'
   OR LOWER(REPO_NAME) LIKE '%openclaw%'  -- explicit include for the June 30 TechEquity session
  )
GROUP BY REPO_NAME
HAVING COUNT(*) >= 10;

-- Run the view (ORDER BY on the SELECT, not inside the view)
SELECT * FROM V_TRENDING_AI_REPOS ORDER BY stars_gained DESC LIMIT 20;


-- ============================================================
-- CHECKPOINT 3 — Natural language summary with CORTEX.COMPLETE
-- ============================================================
-- ALTER ACCOUNT is already in the SETUP block above.
-- If you jumped here directly without running SETUP, run this first:
--   ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'claude-4-sonnet',
    CONCAT(
        'You are a developer trend analyst. ',
        'Based on the following GitHub star data from the last 30 days, ',
        'write a 3-4 sentence summary of what is trending in AI and open source. ',
        'Name the top 3 repositories and why they are gaining momentum. ',
        'Be specific and data-driven. ',
        'Data: ',
        (
            SELECT LISTAGG(
                repo_name || ' — ' || stars_gained || ' stars — ' || description,
                ' | '
            ) WITHIN GROUP (ORDER BY stars_gained DESC)
            FROM (
                SELECT repo_name, stars_gained, description
                FROM V_TRENDING_AI_REPOS
                ORDER BY stars_gained DESC
                LIMIT 10
            )
        )
    )
) AS trend_summary;


-- ============================================================
-- CHECKPOINT 4 — Cortex Search Service on repo names
-- ============================================================
-- NOTE: Requires Checkpoint 2 view (V_TRENDING_AI_REPOS) to exist first.

CREATE OR REPLACE CORTEX SEARCH SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    ON description
    ATTRIBUTES repo_name, stars_gained
    WAREHOUSE = WORKSHOP_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT repo_name, description, stars_gained
    FROM V_TRENDING_AI_REPOS
);

-- Verify it's active (may take 30-60 seconds)
SHOW CORTEX SEARCH SERVICES IN SCHEMA GITTREND_DB.PUBLIC;


-- ============================================================
-- CHECKPOINT 5 — Create the GitTrend Cortex Agent
-- ============================================================

CREATE OR REPLACE AGENT GITTREND_DB.PUBLIC.GITTREND
    COMMENT = 'GitHub trend analyst — 30 days of real star activity'
    FROM SPECIFICATION
$$
models:
  orchestration: "claude-4-sonnet"

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
$$;

-- Verify
SHOW AGENTS IN SCHEMA GITTREND_DB.PUBLIC;

-- NOTE: If GitTrend doesn't initially appear in CoWork, navigate to Agents
-- from the left nav, select the GITTREND agent, confirm that Snowflake CoWork
-- is enabled in the About/Overview section, then select "Preview in Snowflake
-- CoWork" in the top right.


-- ============================================================
-- RUN IT — Test GitTrend via CoWork or Search Preview
-- ============================================================
-- Primary interface: CoWork (left nav → CoWork → find GitTrend → ask questions).
--
-- To test the Cortex Search service directly in SQL:
-- NOTE: Verify SNOWFLAKE.CORTEX.SEARCH_PREVIEW function name is correct
-- for your account version before the event. Alternatively use the REST API:
-- POST /api/v2/databases/GITTREND_DB/schemas/PUBLIC/cortex-search-services/GITHUB_REPO_SEARCH:query
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH',
        '{"query": "fastest growing AI agent framework", "columns": ["repo_name","description","stars_gained"], "limit": 5}'
    )
) AS results;

SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH',
        '{"query": "agentic AI or MCP protocol", "columns": ["repo_name","description","stars_gained"], "limit": 5}'
    )
) AS results;

SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH',
        '{"query": "RAG retrieval augmented generation", "columns": ["repo_name","description","stars_gained"], "limit": 5}'
    )
) AS results;
