# Workshop Guide — v4: Multi-Agent Orchestration

**Format:** Stage presentation (45–60 min) — narrative + live demo, no hands-on build
**Presenter:** Richie Bachala, Sr. Manager of Applied Engineering, Snowflake
**Pre-req:** Familiarity with GitTrend (v1–v3), or none — the recap covers it

---

## What This Level Adds

v1 built a single agent. v2 made it production-ready. v3 governed its cost.
v4 asks: what happens when one agent isn't enough?

This session introduces three multi-agent orchestration patterns — routing,
chaining, and fan-out — using the same GitTrend stack from the workshop series.
It includes a live demo of multi-agent swarms in CoCo Desktop.

**Audience:** 100+ | mixed levels | returns from prior sessions + net-new
**Duration:** 45–60 min depending on event slot
**Surface:** CoCo Desktop (swarms require CoCo Desktop, not Snowsight)

---

## Timing Map (45-min version)

| Section | Duration | Cumulative |
|---|---|---|
| Hook — GitTrend live demo | 4 min | 4 min |
| Act 1: The Arc (v1 → v2 → v3) | 8 min | 12 min |
| Act 2: Three Lessons | 8 min | 20 min |
| Act 3: Multi-Agent Patterns | 18 min | 38 min |
| Act 4: Try It Yourself | 5 min | 43 min |
| Buffer / Q&A | 2 min | 45 min |

For a 60-min slot: expand Act 3 to 25 min (more time on each pattern) and
add 8 min to Q&A.

---

## HOOK (4 min)

Open with GitTrend answering a question — live or pre-recorded clip, 30 seconds.

**Spoken:**
> "Over the past four months, more than 400 people built exactly what you just
> saw — many of them in this room, at this venue. They built it in under 60
> minutes, on their first trial account, using real data: 107 million GitHub events."

> "Tonight: what we learned building that — and what comes after one agent."

---

## ACT 1: THE ARC (8 min)

Walk each version in ~90 seconds:

```
v1  Foundation   "Build it"         — Cortex Agent on 107M events
v2  Production   "Ship it"          — MCP Server + AGENTS.md + CLI-first
v3  Governance   "Run it safely"    — AI credits, Resource Monitor, Budget
```

Show the full GitTrend stack diagram (all layers top to bottom).

**Transition:** "That's everything across three workshops. This is where tonight starts."

---

## ACT 2: THREE LESSONS (8 min)

### Lesson 1: AGENTS.md is a contract, not a comment
It's the system prompt. Precision here beats model tuning. In a multi-agent
system, AGENTS.md is also the interface contract — how one agent discovers another.

### Lesson 2: Data quality beats model quality
We fixed the Cortex Search index, not the model. Same model, same prompt,
different retrieval. Quality jumped immediately.

### Lesson 3: AI credits ≠ platform credits
Resource Monitors cover compute credits. They do NOT cover AI credits.
Three instruments: Resource Monitor, Snowflake Budget, Per-User AI Quota.
More agents = more AI credit usage — this matters when you go from one to many.

**Transition:** "Those three lessons are what one agent teaches you. Now — what
one agent can't do."

---

## ACT 3: MULTI-AGENT ORCHESTRATION (18 min)

### The Single-Agent Ceiling (3 min)

Three problems:
1. **Intent overload** — one prompt handling too many domains degrades
2. **Sequential execution** — one question at a time
3. **Specialist vs. generalist** — a great trend analyst is a mediocre cost analyst

> "The answer isn't a smarter model. It's decomposition."

### Three Patterns (7 min)

**Pattern 1: Routing / Triage**
```
User Query → [Triage Agent — lightweight model] → classify intent
  → Trend Agent | Cost Agent | Research Agent
```
A dispatcher. Routes but doesn't answer. Cost angle: lead agent on a capable
model, subagents on lighter models — explicit cost tiers.

**Pattern 2: Chain / Pipeline**
```
[Agent A: Find trending repos] → [Agent B: Deep-dive] → [Agent C: Draft report]
```
Looks like ETL — except each step is reasoning, not transforming. Snowflake
primitive: Tasks (schedule it as a DAG).

**Pattern 3: Fan-out / Parallel**
```
[Orchestrator] → dispatch N agents → [Aggregator]
```
If Chain is ETL, Fan-out is MapReduce. Wall clock time stays roughly constant
as N grows.

### Industry validation (2 min)

Anthropic research: multi-agent with Opus 4 lead + Sonnet 4 subagents
outperformed single-agent Opus 4 by 90.2%.

The principle: start with one agent. Add tools before agents. Graduate to
multi-agent when you hit clear limits. That's exactly what our workshop arc did.

### Live demo — CoCo Desktop (6 min)

**Part 1 — Routing classification (2 min):**
Run `TRIAGE_INTENT` against 4 test questions. The mixed-intent question
("trending repos AND what did the analysis cost?") routes to `trend` and
drops the cost half — the single-agent ceiling, live.

```sql
SELECT question, TRIAGE_INTENT(question) AS classified
FROM VALUES
  ('What are the most-starred AI repos this week?'),
  ('How many AI credits did I use today?'),
  ('Tell me about the transformers library architecture'),
  ('What are the trending repos and what did the analysis cost?')
AS t(question);
```

**Part 2 — Agent swarm (4 min):**
In CoCo Desktop, spawn a team: trend analyst, cost analyst, research analyst.
Show three agents working in parallel and producing a combined brief.

> "Three agents. Three domains. One brief. No routing SQL needed — CoCo
> dispatched the team and aggregated the results."

**Note:** Agent swarms only work on CoCo Desktop, not Snowsight.

---

## ACT 4: TRY IT YOURSELF (5 min)

Point to the repo:

```
Workshop series (v1–v3, full hands-on builds):
  github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

Multi-agent experiments (Chain + Fan-out, go deeper):
  experiments/multi-agent/
    01-routing-agent  •  02-chain-agent  •  03-fanout-agent
```

For alumni: "Your GitTrend agent is the specialist. The orchestration layer is
what's new tonight."

For newcomers: "Start with v1. Steps 0–3 get you a working agent in 45 minutes."

---

## Snowflake Primitives

| Primitive | Role in multi-agent |
|---|---|
| Tasks | Schedule agent pipelines (Chain pattern, cron) |
| Thread API | Session persistence — transcripts, fork/branch across agent turns |
| Model tiers | Lead agent on capable model, subagents on lighter models for cost efficiency |

---

## Demo Setup (for the presenter)

The live demo requires a Snowflake account with:
- `GITTREND_DB` database with 107M `GITHUB_EVENTS` rows loaded
- `V_TRENDING_AI_REPOS` view created
- `TRIAGE_INTENT` function created (uses `llama3.3-70b` or equivalent available model)
- Cross-region Cortex enabled: `ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION'`
- CoCo Desktop connected to the demo account

The `TRIAGE_INTENT` function:
```sql
CREATE OR REPLACE FUNCTION GITTREND_DB.PUBLIC.TRIAGE_INTENT(question STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
  SELECT TRIM(
    SNOWFLAKE.CORTEX.COMPLETE(
      'llama3.3-70b',
      'Classify this question into exactly one of these categories: trend, cost, research.
       Return only the category word, nothing else.
       - trend: questions about trending repos, stars, velocity, popular projects
       - cost: questions about credit usage, spend, cost, how much something cost
       - research: questions asking for deep analysis of a specific repo or project
       Question: ' || question
    )
  )
$$;
```

Use `CHECKPOINTS.sql` from this repo for the GitTrend stack setup (CP1–5).

---

## On the Competitive Landscape (if asked)

Two lanes in multi-agent: code-execution governance (what Databricks/Omnigent
addresses — security, sandboxing, cross-vendor agent coordination) and
data-native governance (what this work addresses — cost visibility, grounded
retrieval quality, agents that reason over data). Different problems, different
buyers. Don't attack — position.
