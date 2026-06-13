# I Built an AI Agent in 60 Minutes Using Only Natural Language Prompts

*Posted by Richie Bachala, Solutions Architecture Leader — Snowflake*

---

Last week I gave a workshop at the TechEquity AI Forum in Menlo Park. The challenge I set for myself and 60+ engineers in the room: build a working AI agent from scratch, using real data, in under 60 minutes — without writing a single line of SQL manually.

We pulled it off. Here's how.

---

## The Problem With Most AI Agents

The demos are impressive. The production reality is frustrating.

Most AI agents are disconnected from the data that would actually make them useful. They're trained on the internet, they answer in generalities, and when you push them on specifics they hallucinate. The gap between "AI demo" and "AI that's useful at work" isn't a model problem — it's a data problem.

Your model doesn't know your business. It doesn't know your customers, your code, your pipelines, or your community. That knowledge lives in your data. And until your agent has access to that data — governed, real-time, grounded — it's just a sophisticated autocomplete.

**Your data is the moat. Agents are just the interface.**

That's the thesis we built from at the TechEquity AI Forum. And we proved it with 4 billion GitHub events and a warehouse-native coding agent called CoCo.

---

## What We Built: GitTrend

By the end of the session, every person in that room had a working AI agent called **GitTrend** — a Cortex AI agent that answers natural language questions about trending GitHub repositories, powered by real data from the [GH Archive](https://www.gharchive.org/) dataset on Snowflake Marketplace.

You could ask it:

- *"What's the fastest-growing AI project in the last 30 days?"*
- *"What languages dominate trending open source repos right now?"*
- *"Is there anything blowing up in agentic AI or MCP this month?"*

And it answered. Not with a hallucinated opinion — with real answers pulled from 4 billion+ actual GitHub events.

The kicker: **CoCo wrote every SQL statement**. Every `SELECT`, every `CREATE CORTEX SEARCH SERVICE`, every `CREATE CORTEX AGENT`. Attendees directed it in plain English. They never touched SQL directly.

---

## The 5-Step Pattern

Here's what we built, step by step. The same pattern works on any dataset — we used GitHub data because every engineer in the room lives on GitHub, but swap it for your sales data, support tickets, or product telemetry and the steps are identical.

### Step 1 — Mount the data (1 click)

GH Archive is available for free on the [Snowflake Marketplace](https://app.snowflake.com/marketplace). No ingestion, no ETL, no pipeline. One click to mount it as `GH_ARCHIVE` in your account. 4 billion+ GitHub events — pushes, stars, forks, pull requests, issues — ready to query.

### Step 2 — CoCo explores the schema

Open CoCo (Snowflake's coding agent, now generally available) and give it this prompt:

```
I have a database called GH_ARCHIVE mounted from Snowflake Marketplace.
Explore it: list all tables, describe the key columns in each,
and explain what types of GitHub events are tracked.
Tell me which columns would be most useful for finding
trending AI and ML repositories by star activity.
```

CoCo runs `SHOW TABLES`, `DESCRIBE TABLE`, samples rows, and explains the schema in plain English. It identifies `WatchEvent` as a star event, explains the semi-structured `repo` JSON column, and recommends which fields to use. You haven't written anything yet.

### Step 3 — Build the trending repos query

Tell CoCo what you want:

```
Using GH_ARCHIVE.PUBLIC.EVENTS, write a SQL query that finds
the top 20 repositories that gained the most stars in the
last 30 days where the repo name or description suggests
AI, ML, LLM, or agentic tooling. Order by stars gained.
```

CoCo writes a complete SQL query — filtering `WatchEvent` records, handling the semi-structured JSON extraction (`repo:name::string`), grouping by repo, and ordering by star count. You run it. You're looking at real signal: which AI repos the developer community is actually paying attention to right now.

Then ask CoCo to wrap those results in `CORTEX.COMPLETE`:

```
Wrap these results in CORTEX.COMPLETE so instead of returning
rows it returns a 3-4 sentence natural language summary
of what's trending and why.
```

The output shifts from a table of data to a paragraph of insight — grounded in real numbers, zero hallucination.

### Step 4 — Create a Cortex Search Service

`CORTEX.COMPLETE` summarizes. `CORTEX.SEARCH` finds. Now give your agent semantic search capability:

```
Create a Cortex Search Service called GITHUB_REPO_SEARCH
that indexes the repo descriptions and names from the
trending data, so users can search semantically —
for example, "find repos related to autonomous agents."
```

CoCo generates a `CREATE CORTEX SEARCH SERVICE` statement. It indexes the repo descriptions and sets a 1-hour refresh lag against the live data. You run it, wait 30 seconds for the index to build, and you now have semantic search over 4 billion GitHub events.

### Step 5 — Wire the agent

The final step — creating the actual agent:

```sql
CREATE OR REPLACE CORTEX AGENT GITTREND_DB.PUBLIC.GITTREND
    TOOLS = (
        CORTEX_SEARCH_SERVICE GITTREND_DB.PUBLIC.GITHUB_REPO_SEARCH
    )
    COMMENT = 'GitHub trend analyst — 30 days of real star activity'
AS
$$
You are GitTrend, a GitHub trend analyst with access to 30 days of
real GitHub star activity data. Answer questions about trending open
source projects, emerging technologies, and developer community momentum.
Always name specific repositories with their star counts. Be direct.
$$;
```

CoCo wrote this too. You have a named, governed, queryable AI agent — backed by real data, with a defined system prompt, surfaced in CoWork for any team member to use.

Total time from blank screen to working agent: under 60 minutes.

---

## The OpenClaw Moment

Something unexpected happened during the session. When attendees ran the trending repos query in Step 3, **OpenClaw** showed up in the results — the fastest-growing open source project on GitHub in 2026, a local AI assistant that had been the subject of another workshop at the same event earlier that afternoon.

The room went quiet for a second.

Then someone said: "We just built an agent that already knows about the thing we built this afternoon."

That's the moment. Your agent isn't impressive because it knows a lot — it's impressive because it knows *your* data, in real time, and it discovered something relevant without being told to look for it.

That doesn't happen with a generic chatbot. It happens when you give an agent real, governed, live data.

---

## Why CoCo Changes the Equation

Earlier this year, Dario Amodei — CEO of Anthropic, whose Claude models power CoCo — wrote this:

> *"Some of the strongest engineers I've ever met are now handing over almost all their coding to AI."*

That's not a sales pitch. That's the person who built the model telling you what he's observing among the best engineers in the industry. What we did in the workshop tonight is exactly that — 60+ engineers handing their SQL to an AI, directing it rather than writing it, and shipping a working agent in 60 minutes.

The traditional path to building a data-backed AI agent looks like this: understand the schema, write the data prep SQL, write the search service DDL, write the agent definition, debug the joins, tune the prompts, iterate. That's a multi-day project for an experienced data engineer.

With CoCo, it's a directed conversation. You describe what you want. CoCo writes the SQL, explains what it did, and executes. You verify and move on.

The skill shift is real: you're no longer writing SQL — you're **directing a coding agent** that writes SQL. The leverage is significant, especially for teams where the people closest to the business problem aren't necessarily SQL experts.

---

## Take This Further

The 5-step pattern we used isn't specific to GitHub data. It works on any dataset:

- **Customer support tickets** → agent that answers "what's the most common issue this week?"
- **Sales pipeline data** → agent that surfaces "which deals need attention today?"
- **Internal documentation** → agent that answers "how does our authentication system work?"
- **Product telemetry** → agent that answers "which features are struggling with adoption?"

The data changes. The pattern stays the same.

---

## Resources

Everything from the workshop is open and available:

**Workshop repo:** [github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)

Includes the full step-by-step guide and all checkpoint SQL — whether you attended the session or are working through it on your own.

**Further reading:**
- [Getting Started with Cortex Agents](https://www.snowflake.com/en/developers/guides/getting-started-with-cortex-agents/)
- [Build an End-to-End App with CoCo](https://www.snowflake.com/en/developers/guides/sfguide-build-end-to-end-ai-app-on-snowflake/)
- [Getting Started with Snowflake CoWork](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-cowork/)
- [Getting Started with the Snowflake MCP Server](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-mcp-server/)
- [Free Snowflake trial](https://snowflake.com/try)

---

*Richie Bachala is a Solutions Architecture Leader at Snowflake based in the San Francisco Bay Area.*
*He presented this workshop at the TechEquity AI Forum on June 30, 2026 at the Snowflake SVAI Hub in Menlo Park.*
