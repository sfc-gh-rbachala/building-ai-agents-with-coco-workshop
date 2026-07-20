# Building AI Agents with Snowflake CoCo — Level 2

**TechEquity AI Forum — July 28, 2026 | 7:00 PM | Snowflake SVAI Hub, Menlo Park**

Workshop materials for *Foundation to Intelligence Series — Level 2: Build, Extend, and Expose a Production AI Agent*, presented by [Richie Bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/), Solutions Architecture Leader at Snowflake.

**Level: Intermediate / Advanced**

---

## ⚠️ Pre-Work — Complete Before Arriving

This session runs in the **CoCo CLI**, not the Snowsight UI. Two things to do before you get there:

### 1. Install CoCo CLI

**macOS / Linux / WSL:**
```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

Confirm the install worked: `cortex --version`

### 2. Create a free Snowflake trial account

Use this event-specific link — it activates all AI features automatically:

**[Sign up here →](https://signup.snowflake.com/?t=aaf6ac35aa6362f3f3a48ca28405ade45a945e7e5054586a923a4d62dfbada9d)**

Choose **AWS US East (Ohio)** when prompted. Select **AI Data Cloud** as your use case. Do not select AWS US East (N. Virginia).

> **⚠️ Timing matters:** This link only activates AI features for accounts created **July 26–31, 2026 (UTC)**. Don't sign up before July 26 — you'll get a standard trial without the AI features needed for this workshop.

> If you attended the June forum, your existing account is fine — just install the CoCo CLI above.

---

## What You'll Build

**GitTrend v2** — a production AI agent exposed via MCP, queryable from Claude Desktop, Cursor, VS Code, or any MCP-compatible tool. Powered by 107M real GitHub events.

![GitTrend answering questions in CoWork](gittrend-showcase.gif)

Ask it:
- *"What's the fastest-growing AI project in the last 30 days?"*
- *"Is there anything blowing up around MCP or agentic AI this month?"*
- *"Show me a bar chart of the top 10 repos by stars."*

**The MCP connection to the 3:30 session:** Saurabh's MCP security workshop covers how to attack and defend MCP endpoints. This session builds the endpoint. You leave with both halves.

CoCo writes every SQL statement from your terminal. You direct it. You own the result.

---

## Workshop Files

| File | What it is |
|---|---|
| [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | Step-by-step guide — follow this during the session |
| [`CHECKPOINTS.sql`](CHECKPOINTS.sql) | Fallback SQL for each step — use if CoCo gets stuck |

---

## The 6-Step Pattern

```
0. AGENTS.md + CLI    →  cortex connections create; cortex code; CoCo reads your context
1. Load the data      →  107M GitHub events via COPY INTO from public S3
2. CoCo explores      →  Describe schema, find the right columns
3. Build the query    →  Trending AI repos by star activity, last 30 days (VIEW)
4. Add AI_COMPLETE    →  Turn SQL results into natural language
5. Wire the agent     →  Cortex Search + Cortex Agent = GitTrend
6. Expose via MCP     →  CREATE MCP SERVER + OAuth → query from Claude Desktop / Cursor
```

Same pattern works on any dataset in your organization.

---

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  107M real GitHub events (S3)
CoCo CLI                           →  writes the code (your terminal)
V_TRENDING_AI_REPOS                →  trending AI repos by star activity
AI_COMPLETE                        →  turns SQL results into language
GITHUB_REPO_SEARCH                 →  Cortex Search Service (semantic index)
GITTREND                           →  Cortex Agent (search + complete + system prompt)
GITTREND_MCP                       →  MCP Server — exposes GitTrend to any MCP client
```

---

## Resources

- [Free Snowflake trial (event link)](https://signup.snowflake.com/?t=aaf6ac35aa6362f3f3a48ca28405ade45a945e7e5054586a923a4d62dfbada9d)
- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

## Looking for the June 30 Workshop?

The v1 session (*Build an AI Agent in 60 Minutes*) materials are preserved in the git history of this repo. The core build pattern is the same — v2 adds a CLI-first workflow, `auto` model selection, and MCP as a core step.

---

## About the Presenter

**Richie Bachala** — Solutions Architecture Leader, Snowflake
[snowflake.com/en/blog/authors/richie-bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/)

---

*TechEquity AI Forum | July 28, 2026 | Snowflake SVAI Hub, 135 Constitution Dr, Menlo Park, CA*
