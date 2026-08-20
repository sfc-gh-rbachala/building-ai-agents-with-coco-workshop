-- ============================================================
-- GITTREND WORKSHOP CHECKPOINTS
-- Building AI Agents with Snowflake CoCo
-- Companion to WORKSHOP-GUIDE.md
--
-- Use these if CoCo gets stuck or you fall behind.
-- Run each checkpoint in a Snowflake SQL Worksheet or via snow sql.
--
-- Map to guide steps:
--   SETUP         -> Step 2 (load the data)
--   Checkpoint 1  -> Step 3a (explore schema)
--   Checkpoint 2  -> Step 3b (V_TRENDING_AI_REPOS)
--   Checkpoint 3  -> Step 4a (AI_COMPLETE)
--   Checkpoint 4  -> Step 4b (Cortex Search Service)
--   Checkpoint 5  -> Step 5a (Cortex Agent)
--   Checkpoint 6  -> Stretch step (MCP Server + OAuth) - take-home, optional
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

-- Verify row count — expect 107,752,158 rows.
-- A materially lower number means the COPY INTO did not finish. Re-run the COPY INTO
-- above; it is safe to repeat because the table is CREATE OR REPLACE.
SELECT COUNT(*) FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS;

-- Confirm the data window. Expect a max around 2026-06-18; the analytical filters below
-- assume 2026-05-19 to 2026-06-19 and will need adjusting if this dataset ever changes.
SELECT MIN(CREATED_AT) AS earliest, MAX(CREATED_AT) AS latest
FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS;


-- ============================================================
-- CHECKPOINT 1 — Explore the GITHUB_EVENTS schema
-- ============================================================

DESCRIBE TABLE GITTREND_DB.PUBLIC.GITHUB_EVENTS;

-- Sample 5 rows to see the structure
SELECT * FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS LIMIT 5;

-- See all event types available
SELECT EVENT_TYPE, COUNT(*) AS event_count
FROM GITTREND_DB.PUBLIC.GITHUB_EVENTS
WHERE CREATED_AT >= '2026-05-19' AND CREATED_AT < '2026-06-19'
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
  AND CREATED_AT >= '2026-05-19' AND CREATED_AT < '2026-06-19'
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
  AND CREATED_AT >= '2026-05-19' AND CREATED_AT < '2026-06-19'
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

-- On REFRESH_MODE: this uses the default, INCREMENTAL, which was verified working
-- end-to-end on a trial account against this exact SQL. Docs note that creation fails
-- if a source query can't be incrementalized, and this source is an aggregate view
-- (GROUP BY + HAVING) over 107M rows — but in practice Snowflake handles it.
-- If you ever DO hit an incremental-refresh error here, add: REFRESH_MODE = FULL
-- (safe for this workshop, since the source data is static).

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
    GitHub star activity data from the GitHub Archive.
    Your data covers 19 May 2026 through 18 June 2026 and does not update.
    When a user says "the last 30 days", "this month", or "right now", interpret it
    as that fixed window, and state the window in your answer so the user is never
    misled into thinking the data is current. You help users discover
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

-- To test in CoWork: left nav → AI & ML → Agents → GITTREND → Preview → Preview in Snowflake CoWork
-- (two clicks after selecting the agent, not one)


-- ============================================================
-- CHECKPOINT 6 — Create the MCP Server and OAuth Integration
-- ============================================================
-- STRETCH / TAKE-HOME STEP — not required to finish the core build.
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
-- OAUTH_REDIRECT_URI below is for claude.ai (web interface at claude.ai/chat).
-- For Claude Desktop app: use the localhost URI shown during Desktop's connector setup.
-- For Cursor: use the redirect URI shown during Cursor's OAuth setup flow.
CREATE OR REPLACE SECURITY INTEGRATION GITTREND_MCP_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback';

-- Step 3: Retrieve client credentials (save these — you need them for client config)
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('GITTREND_MCP_OAUTH');

-- Step 4: Set your user's default role + warehouse (required for MCP OAuth sessions)
SET MY_USER = CURRENT_USER();
ALTER USER IDENTIFIER($MY_USER) SET DEFAULT_ROLE = 'ACCOUNTADMIN' DEFAULT_WAREHOUSE = 'WORKSHOP_WH';


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
-- CHECKPOINT 7 — Cost visibility: AI credit usage (multi-view)
-- ============================================================
-- v3 Step 4. Requires ACCOUNTADMIN role.
-- Multi-view approach validated on a fresh trial account:
--   METERING_HISTORY                    — high-level summary,  ~3 hr lag
--   CORTEX_AI_FUNCTIONS_USAGE_HISTORY   — per-user/model detail, ≤5 min lag  ← start here on trial accounts
--   CORTEX_AGENT_USAGE_HISTORY          — per-agent detail,     up to 1 hr lag
--   SNOWFLAKE_COWORK_USAGE_HISTORY      — CoWork sessions,      up to 1 hr lag
-- Service type in METERING_HISTORY: AI_FUNCTIONS (not AI_INFERENCE)

USE ROLE ACCOUNTADMIN;

-- ---- Part A: METERING_HISTORY — high-level summary ----
-- Breakdown by service type (last 7 days). May be sparse on brand-new accounts (~3 hr lag).
SELECT
    SERVICE_TYPE,
    ROUND(SUM(CREDITS_USED), 4) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP)
GROUP BY SERVICE_TYPE
ORDER BY credits_used DESC;

-- Wider window fallback (last 30 days) — use if account is new and 7-day window is sparse
SELECT
    SERVICE_TYPE,
    ROUND(SUM(CREDITS_USED), 4) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP)
GROUP BY SERVICE_TYPE
ORDER BY credits_used DESC;

-- Part B: CORTEX_AI_FUNCTIONS_USAGE_HISTORY — ≤5 min lag (SLA), ~2 min typical ----
-- Per-user, per-function, per-model detail. Works on brand-new accounts.
SELECT
    COALESCE(u.NAME, '(system)') AS user_name,
    f.FUNCTION_NAME,
    f.MODEL_NAME,
    COUNT(*) AS call_count,
    ROUND(SUM(f.CREDITS), 6) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY f
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.USERS u ON f.USER_ID = u.USER_ID
WHERE f.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP)
GROUP BY 1, 2, 3
ORDER BY credits_used DESC;

-- ---- Part C: CORTEX_AGENT_USAGE_HISTORY — up to 1 hr lag ----
-- Per-agent, per-user token credit breakdown.
SELECT
    AGENT_NAME,
    USER_NAME,
    ROUND(SUM(TOKEN_CREDITS), 6) AS token_credits_used,
    SUM(TOKENS)                  AS total_tokens
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP)
GROUP BY AGENT_NAME, USER_NAME
ORDER BY token_credits_used DESC;

-- ---- Part D: SNOWFLAKE_COWORK_USAGE_HISTORY — up to 1 hr lag ----
-- CoWork session credits per user.
SELECT
    USER_NAME,
    AGENT_NAME,
    ROUND(SUM(TOKEN_CREDITS), 6) AS token_credits_used,
    SUM(TOKENS)                  AS total_tokens
FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWFLAKE_COWORK_USAGE_HISTORY
WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP)
GROUP BY USER_NAME, AGENT_NAME
ORDER BY token_credits_used DESC;


-- ============================================================
-- CHECKPOINT 8 — Resource monitor on WORKSHOP_WH (compute credits only)
-- ============================================================
-- v3 Step 5 Part 1.
-- IMPORTANT: Resource Monitors cover warehouse COMPUTE credits only.
-- They do NOT cover AI credits (Cortex Agents, AI Functions, CoCo, CoWork).
-- AI credits are a separate billing unit (since April 2026, $2.00/credit flat).
-- For AI cost control use Budgets (Part 2) and Per User Quotas (Part 3).

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE RESOURCE MONITOR WORKSHOP_AI_MONITOR
  WITH CREDIT_QUOTA = 10
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS ON 80 PERCENT DO NOTIFY
           ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE WORKSHOP_WH SET RESOURCE_MONITOR = WORKSHOP_AI_MONITOR;

-- Verify
SHOW RESOURCE MONITORS LIKE 'WORKSHOP_AI_MONITOR';


-- ============================================================
-- CHECKPOINT 8b — Account Budget (account-wide spending ceiling)
-- ============================================================
-- v3 Step 5 Part 2.
-- The account budget monitors ALL credit usage in your account:
-- AI_SERVICES, WAREHOUSE_METERING, CORTEX_SEARCH, and more.
-- No tag setup required — works on any account immediately.

USE ROLE ACCOUNTADMIN;

-- Activate the built-in account budget (one-time per account)
CALL snowflake.local.account_root_budget!ACTIVATE();

-- Set a monthly spending limit (50 credits covers a full workshop build)
CALL snowflake.local.account_root_budget!SET_SPENDING_LIMIT(50);

-- Verify the spending limit is set
CALL snowflake.local.account_root_budget!GET_SPENDING_LIMIT();

-- ⚠ Email notifications are NOT set here.
-- SET_EMAIL_NOTIFICATIONS requires a verified email address AND a pre-configured
-- email notification integration (CREATE NOTIFICATION INTEGRATION TYPE=EMAIL +
-- GRANT USAGE ... TO APPLICATION SNOWFLAKE). That setup is out of scope for a
-- live workshop on a trial account.
-- Use the Snowsight path instead:
--   Admin → Cost Management → Budgets → Account Budget
--   The UI validates the logged-in user's verified email automatically.


-- ============================================================
-- CHECKPOINT 8c — Per User AI Quota (per-user enforcement)
-- ============================================================
-- v3 Step 5 Part 3.
-- Per User Quotas cap how many AI credits any single user can burn per cycle.
-- Covers AI Functions, Cortex Agents, CoCo, and CoWork.
-- NOTE: minimum limit is 1 credit (integer only).

-- Step 1: create the quota object
CREATE OR REPLACE SNOWFLAKE.CORE.QUOTA WORKSHOP_AI_QUOTA();

-- Step 2: add the AI domains to monitor
CALL WORKSHOP_AI_QUOTA!ADD_SHARED_RESOURCE('AI FUNCTION');
CALL WORKSHOP_AI_QUOTA!ADD_SHARED_RESOURCE('CORTEX AGENT');
CALL WORKSHOP_AI_QUOTA!ADD_SHARED_RESOURCE('SNOWFLAKE INTELLIGENCE'); -- CoWork
CALL WORKSHOP_AI_QUOTA!ADD_SHARED_RESOURCE('CORTEX CODE');            -- CoCo

-- Step 3: set per-user spending limits
CALL WORKSHOP_AI_QUOTA!SET_PER_USER_LIMIT(20);          -- monthly
CALL WORKSHOP_AI_QUOTA!SET_PER_USER_LIMIT(5, 'DAILY');  -- daily

-- Step 4: optionally enable block enforcement (first arg: enable, second arg: notify user)
-- CALL WORKSHOP_AI_QUOTA!SET_BLOCK_ENFORCEMENT_ENABLED(TRUE, TRUE);

-- Verify config
CALL WORKSHOP_AI_QUOTA!GET_CONFIG();

-- Check who (if anyone) is currently blocked
CALL WORKSHOP_AI_QUOTA!GET_ACTIVE_BLOCKS_V2();

-- OR: use the Snowsight wizard (same result, no SQL required):
-- Admin → Cost Management → Budgets → + Budget → Quota
--   Scope: All users · AI-related features
--   Basic info: name WORKSHOP_AI_QUOTA, schema GITTREND_DB.PUBLIC
--   Monthly 20 · Daily 5 · Enable enforcement on


-- ============================================================
-- CHECKPOINT 9 — Cost trend for Step 6 (chart + optimization)
-- ============================================================
-- v3 Step 6. Daily breakdown for visualization + total for "what did it all cost?"

USE ROLE ACCOUNTADMIN;

-- Total by service type — the "what did this workshop cost?" summary
-- Note: AI_FUNCTIONS won't appear here until ~3 hr after the session on trial accounts.
-- Use the CORTEX_AI_FUNCTIONS_USAGE_HISTORY query below for live AI cost data.
SELECT
    SERVICE_TYPE,
    ROUND(SUM(CREDITS_USED), 4)                        AS total_credits,
    COUNT(DISTINCT DATE_TRUNC('DAY', START_TIME))       AS days_active
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP)
GROUP BY SERVICE_TYPE
ORDER BY total_credits DESC;

-- Daily AI credit trend — CORTEX_AI_FUNCTIONS_USAGE_HISTORY (≤5 min lag)
-- Use this for the inline chart on trial accounts: METERING_HISTORY won't
-- show AI_FUNCTIONS credits until ~3 hr after the session ends.
SELECT
    DATE_TRUNC('DAY', START_TIME)       AS usage_day,
    FUNCTION_NAME,
    MODEL_NAME,
    ROUND(SUM(CREDITS), 6)              AS credits_used,
    COUNT(*)                            AS call_count
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY
WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP)
GROUP BY 1, 2, 3
ORDER BY 1 ASC, 4 DESC;


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
