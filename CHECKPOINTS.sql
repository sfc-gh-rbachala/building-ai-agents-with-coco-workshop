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
CREATE WAREHOUSE IF NOT EXISTS DASH_XS_WH WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60;
USE DATABASE GITTREND_DB;
USE SCHEMA GITTREND_DB.PUBLIC;
USE WAREHOUSE DASH_XS_WH;
-- Required for CORTEX.COMPLETE (run this now, not later)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';


-- ============================================================
-- CHECKPOINT 1 — Explore the GH Archive schema
-- ============================================================
-- Understand what tables exist and what WatchEvent means

SHOW TABLES IN GH_ARCHIVE.PUBLIC;

DESCRIBE TABLE GH_ARCHIVE.PUBLIC.EVENTS;

-- Sample 5 rows to see the structure
SELECT * FROM GH_ARCHIVE.PUBLIC.EVENTS LIMIT 5;

-- See all the event types available
SELECT type, COUNT(*) AS event_count
FROM GH_ARCHIVE.PUBLIC.EVENTS
WHERE created_at >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY type
ORDER BY event_count DESC;

-- Preview star events (WatchEvent = someone starred a repo)
SELECT
    type,
    repo:name::string          AS repo_name,
    repo:description::string   AS repo_description,
    actor:login::string        AS starred_by,
    created_at
FROM GH_ARCHIVE.PUBLIC.EVENTS
WHERE type = 'WatchEvent'
  AND created_at >= DATEADD('day', -1, CURRENT_TIMESTAMP())
LIMIT 20;


-- ============================================================
-- CHECKPOINT 2 — Trending AI repos by stars (last 30 days)
-- ============================================================

CREATE OR REPLACE VIEW GITTREND_DB.PUBLIC.V_TRENDING_AI_REPOS AS
SELECT
    repo:name::string                                    AS repo_name,
    COALESCE(repo:description::string, repo:name::string) AS description,
    COUNT(*)                                             AS stars_gained,
    MIN(created_at)                                      AS first_star_at,
    MAX(created_at)                                      AS last_star_at
FROM GH_ARCHIVE.PUBLIC.EVENTS
WHERE type = 'WatchEvent'
  AND created_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
  AND (
      LOWER(repo:name::string)        LIKE '%llm%'
   OR LOWER(repo:name::string)        LIKE '%agent%'
   OR LOWER(repo:name::string)        LIKE '%gpt%'
   OR LOWER(repo:name::string)        LIKE '%ai%'
   OR LOWER(repo:name::string)        LIKE '%ml%'
   OR LOWER(repo:name::string)        LIKE '%mcp%'
   OR LOWER(repo:description::string) LIKE '%large language model%'
   OR LOWER(repo:description::string) LIKE '%agentic%'
   OR LOWER(repo:description::string) LIKE '%open source ai%'
   OR LOWER(repo:description::string) LIKE '%cortex%'
  )
GROUP BY repo_name, description
HAVING COUNT(*) >= 10;

-- Run the view (ORDER BY on the SELECT, not inside the view)
SELECT * FROM V_TRENDING_AI_REPOS ORDER BY stars_gained DESC LIMIT 20;


-- ============================================================
-- CHECKPOINT 3 — Natural language summary with CORTEX.COMPLETE
-- ============================================================
-- Note: ALTER ACCOUNT is already in SETUP above.
-- If you skipped SETUP and came here directly, run this first:

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
-- CHECKPOINT 4 — Cortex Search Service on repo descriptions
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    ON description
    ATTRIBUTES repo_name, stars_gained
    WAREHOUSE = DASH_XS_WH
    TARGET LAG = '1 hour'
AS (
    SELECT
        repo_name,
        COALESCE(description, repo_name) AS description,
        stars_gained
    FROM V_TRENDING_AI_REPOS
    WHERE description IS NOT NULL
);

-- Verify it's active (may take 30-60 seconds)
SHOW CORTEX SEARCH SERVICES IN SCHEMA GITTREND_DB.PUBLIC;


-- ============================================================
-- CHECKPOINT 5 — Create the GitTrend Cortex Agent
-- ============================================================

CREATE OR REPLACE CORTEX AGENT GITTREND_DB.PUBLIC.GITTREND
    TOOLS = (
        CORTEX_SEARCH_SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    )
    COMMENT = 'GitHub trend analyst — 30 days of real star activity'
AS
$$
You are GitTrend, a GitHub trend analyst with access to 30 days of
real GitHub star activity data from the GH Archive dataset.

You answer questions about:
- Trending open source projects and repositories
- Emerging technologies and programming languages
- Developer community momentum and breakout projects
- Comparisons between repos, topics, or categories

When answering:
- Always name specific repositories with their star counts
- Note the primary language or category when relevant
- If asked about a topic (e.g., "agentic AI"), search for it directly
- Be direct — developers want signal, not noise
- Do not make claims that are not supported by the data you have access to
- If you are unsure, say so rather than guessing
$$;

-- Verify
SHOW CORTEX AGENTS IN SCHEMA GITTREND_DB.PUBLIC;


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
