# Building AI Agents with Snowflake CoCo

**TechEquity AI Forum — June 30, 2026 | 7:00 PM | Snowflake SVAI Hub, Menlo Park**

Workshop materials for *Build an AI Agent in 60 Minutes with Snowflake CoCo*, presented by [Richie Bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/), Solutions Architecture Leader & Zach Martin, Solutions Consultant — Snowflake.

![Workshop demo — 5-step CoCo build](TechEquity-Workshop-Demo.gif)

---

## Demo Videos

| Video | Link |
|---|---|
| 1 — Intro & Overview | [Watch →](https://youtu.be/Fnx0xtOC92I) |
| 2 — Full Build (Step-by-Step) | [Watch →](https://youtu.be/0o_7TmiaeGY) |
| 3 — Bonus: Export to Stage | [Watch →](https://youtu.be/Fnx0xtOC92I) |

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

## What to Bring

**Just your laptop and a willingness to build.**

We handle everything in the session — account signup, data load, and agent creation all happen live together. No prep needed.

If you want a head start: sign up for a free Snowflake trial using the event link below **before arriving** and run the setup SQL in Step 0 of the Workshop Guide. It loads ~107M GitHub events (~4 min) and means you'll be building from minute one.

**[Event trial signup](https://signup.snowflake.com/?t=521d04bacb9556ae0a2fcb837fbf1db2e78f9e0581a062acb9c7e4100ac1eba6)** — choose **AWS US East (Ohio)**, select **AI Data Cloud**. Do not select AWS US East (N. Virginia).

---

## Workshop Files

| File | What it is |
|---|---|
| [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | Step-by-step guide — follow this during the session |
| [`CHECKPOINTS.sql`](CHECKPOINTS.sql) | Fallback SQL for each step — use if CoCo gets stuck |
| [`workshop-materials/`](workshop-materials/) | Slides and additional post-event resources |

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
- [CoCo documentation](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-snowsight)
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Build an End-to-End App with CoCo](https://www.snowflake.com/en/developers/guides/sfguide-build-end-to-end-ai-app-on-snowflake/)
- [Getting Started with Snowflake CoWork](https://docs.snowflake.com/en/user-guide/snowflake-cortex/snowflake-cowork)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Getting Started with Snowflake Cortex AI](https://quickstarts.snowflake.com/guide/getting-started-with-snowflake-cortex-ai/)

---

## About the Presenters

**Richie Bachala** — Solutions Architecture Leader, Snowflake
[snowflake.com/en/blog/authors/richie-bachala](https://www.snowflake.com/en/blog/authors/richie-bachala/)

**Zach Martin** — Solutions Consultant, Snowflake

---

*TechEquity AI Forum | June 30, 2026 | Snowflake SVAI Hub, 135 Constitution Dr, Menlo Park, CA*
