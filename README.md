# Building AI Agents with Snowflake CoCo

Workshop materials for building a **production AI agent on 107 million real GitHub events** — with zero SQL written by hand.

Presented by [Richie Bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/), Solutions Architecture Leader at Snowflake.

---

## Workshop Levels

Three levels, one dataset. Each level builds on the previous.

| Level | Guide | Duration | MCP | Best for |
|---|---|---|---|---|
| v1 | [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | 60 min | Take-home | Mixed audiences, large rooms |
| v2 | [`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md) | 75 min | Live | Technical audiences, smaller rooms |
| v3 | [`WORKSHOP-GUIDE-V3.md`](WORKSHOP-GUIDE-V3.md) | ~75 min | Carried from v2 | Infrastructure / cost focus |

See [`VERSION.md`](VERSION.md) for the full level comparison and checkpoint map.

---

## Attending a live session?

Pre-work, trial signup links, and timing for each event are in the [`events/`](events/) folder.

Working through this on your own? Grab a [free Snowflake trial](https://signup.snowflake.com/) and follow the guide. You may need to enable cross-region inference: `ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';`

---

## Pre-Work

### Install the CoCo CLI

This workshop runs in the **CoCo CLI**, not the Snowsight UI.

**macOS / Linux / WSL:**
```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

Confirm the install: `cortex --version`

### Get a Snowflake account

Use the event-specific link on your event page above.

---

## Why CoCo

General-purpose AI coding tools start blind to your schemas, roles, and warehouses. They burn time and tokens interrogating you before they can build anything.

CoCo starts with your data context already in hand. That's the whole difference, and you'll feel it in the first five minutes.

---

## What You'll Build

**GitTrend** — an AI agent grounded in 107M real GitHub events.

![GitTrend answering questions in CoWork](media/gittrend-showcase.gif)

Ask it:
- *"What's the fastest-growing AI project in the last 30 days?"*
- *"Is there anything blowing up around MCP or agentic AI this month?"*
- *"Show me a bar chart of the top 10 repos by stars."*

CoCo writes every SQL statement. You direct it. You own the result.

---

## The Pattern

**v1 — 5-step build (60 min):**

```
1. Set the context   →  AGENTS.md + cortex CLI; CoCo learns your account
2. Load the data     →  107M GitHub events via COPY INTO from public S3
3. Explore & build   →  CoCo reads the schema, builds V_TRENDING_AI_REPOS
4. Add intelligence  →  AI_COMPLETE summaries + Cortex Search Service
5. Wire the agent    →  Cortex Agent = GitTrend, ready to answer questions
```

**v2 — 4-block build (75 min), MCP live:**

```
Step 0  Set the context    AGENTS.md + CoCo CLI
Step 1  Load the data      107M GitHub events from public S3
Step 2  Build the agent    5 rapid sub-prompts: explore → view → AI_COMPLETE → Search → Agent
Step 3  Wire the MCP       CREATE MCP SERVER + OAuth + connect Claude/Cursor/CoCo Desktop
```

The same pattern works on any dataset in your organization. Swap `GITHUB_EVENTS`
for your support tickets, sales pipeline, or product telemetry — same prompts,
different schema.

---

## The Stack

```
GITTREND_DB.PUBLIC.GITHUB_EVENTS  →  107M real GitHub events (public S3)
CoCo CLI                          →  writes the code (your terminal)
V_TRENDING_AI_REPOS               →  trending AI repos by star activity
AI_COMPLETE                       →  turns SQL results into language
GITHUB_REPO_SEARCH                →  Cortex Search Service (semantic index)
GITTREND                          →  Cortex Agent (search + chart + system prompt)
GITTREND_MCP                      →  MCP Server — exposes GitTrend anywhere
```

---

## Repo Contents

| File | What it is |
|---|---|
| [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | v1 build guide — 5 steps, MCP take-home |
| [`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md) | v2 build guide — Steps 0–3 (4 blocks), MCP live |
| [`WORKSHOP-GUIDE-V3.md`](WORKSHOP-GUIDE-V3.md) | v3 guide — cost intelligence (under development) |
| [`VERSION.md`](VERSION.md) | Level comparison, checkpoint map, delivery lineage |
| [`CHECKPOINTS.sql`](CHECKPOINTS.sql) | Fallback SQL for every step — use if CoCo gets stuck |
| [`events/`](events/) | Per-event details: date, venue, signup link, timing, level |
| [`sample_weekly_digest_skill.md`](sample_weekly_digest_skill.md) | Example Agent Skill to extend GitTrend |
| [`media/`](media/) | Deck PDF and demo recordings |

---

## Resources

- [Snowflake-managed MCP Server docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [CoCo CLI documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

## About the Presenter

**Richie Bachala** — Solutions Architecture Leader, Snowflake
[Blog](https://www.snowflake.com/en/blog/authors/richie-bachala/) · [LinkedIn](https://www.linkedin.com/in/richiebachala/)
