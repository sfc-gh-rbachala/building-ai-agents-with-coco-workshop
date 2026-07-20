-- ============================================================
-- GITTREND WORKSHOP CHECKPOINTS
-- Foundation to Intelligence Series — Level 2
-- TechEquity AI Forum | July 28, 2026
-- Use these if CoCo gets stuck or you fall behind.
-- Run each checkpoint in a Snowflake SQL Worksheet or via snow sql.
-- ============================================================

-- SETUP (run once at the start)
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS GITTREND_DB;
CREATE SCHEMA IF NOT EXISTS GITTREND_DB.PUBLIC;
CREATE WAREHOUSE IF NOT EXISTS WORKSHOP_WH WAREHOUSE_SIZE = SMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE WORKSHOP_WH;
-- Required for AI_COMPLETE cross-region inference
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

DESCRIBE TABLE GITTREND_DB.PUBLIC.GITHUB_EVENTS;

-- Sample 5 rows to see the structure
SELECT * FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS LIMIT 5;

-- See all event types available
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
   OR LOWER(REPO_NAME) LIKE '%open%'
  )
GROUP BY REPO_NAME
HAVING COUNT(*) >= 10;

-- Run the view (ORDER BY on the SELECT, not inside the view)
SELECT * FROM V_TRENDING_AI_REPOS ORDER BY stars_gained DESC LIMIT 20;


-- ============================================================
-- CHECKPOINT 3 — Natural language summary with AI_COMPLETE
-- ============================================================
-- NOTE: Use AI_COMPLETE — CORTEX.COMPLETE is deprecated (EOL end of 2026).
-- If you jumped here directly without running SETUP, run this first:
--   ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

SELECT AI_COMPLETE(
    'claude-sonnet-4-6',
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

-- NOTE: orchestration: auto — Snowflake picks the best available model automatically
CREATE OR REPLACE AGENT GITTREND_DB.PUBLIC.GITTREND
    COMMENT = 'GitHub trend analyst — 30 days of real star activity'
    FROM SPECIFICATION
$$
models:
  orchestration: auto

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
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"

tool_resources:
  github_repo_search:
    name: "GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH"
    max_results: 10
$$;

-- Verify
SHOW AGENTS IN SCHEMA GITTREND_DB.PUBLIC;

-- To test in CoWork: left nav → AI & ML → Agents → GITTREND → Preview in Snowflake CoWork


-- ============================================================
-- CHECKPOINT 6 — Create the MCP Server and OAuth Integration
-- ============================================================
-- This exposes GITTREND to Claude Desktop, Cursor, and any MCP-compatible client.

-- Step 1: Create the MCP Server object
CREATE OR REPLACE MCP SERVER GITTREND_DB.PUBLIC.GITTREND_MCP
  FROM SPECIFICATION $$
    tools:
      - name: "gittrend"
        type: "CORTEX_AGENT_RUN"
        identifier: "GITTREND_DB.PUBLIC.GITTREND"
        title: "GitTrend — GitHub Trend Analyst"
        description: >
          GitHub trend analyst with 30 days of real star activity data.
          Ask about trending repos, emerging AI/ML projects, and developer momentum.
  $$;

-- Verify
SHOW MCP SERVERS IN SCHEMA GITTREND_DB.PUBLIC;

-- Step 2: Create OAuth security integration
-- OAUTH_REDIRECT_URI below is for Claude Desktop.
-- For Cursor: change to the redirect URI shown during Cursor's OAuth setup flow.
CREATE OR REPLACE SECURITY INTEGRATION GITTREND_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback';

-- Step 3: Retrieve client credentials (save these — you need them for client config)
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('GITTREND_MCP_OAUTH');

-- Step 4: Set your user's default role + warehouse (required for MCP OAuth sessions)
-- Replace <your_username> with your Snowflake username
ALTER USER <your_username> SET DEFAULT_ROLE = 'ACCOUNTADMIN' DEFAULT_WAREHOUSE = 'WORKSHOP_WH';


-- ============================================================
-- MCP Server URL
-- ============================================================
-- Connect MCP clients to this URL:
--
--   https://<account-url>/api/v2/databases/GITTREND_DB/schemas/PUBLIC/mcp-servers/GITTREND_MCP
--
-- IMPORTANT: Use hyphens (-) instead of underscores (_) in your account URL hostname.
-- Example: myorg-myaccount.snowflakecomputing.com (correct)
--          my_org_my_account.snowflakecomputing.com (may cause MCP connection issues)
--
-- To find your account URL: Admin → Accounts in Snowsight → copy the account identifier
-- Format: https://<orgname>-<accountname>.snowflakecomputing.com


-- ============================================================
-- RUN IT — Test via Search Preview (fallback, no MCP client needed)
-- ============================================================

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
