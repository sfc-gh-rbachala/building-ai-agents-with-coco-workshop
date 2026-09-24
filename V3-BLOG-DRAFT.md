# Your AI agent is live. Now what does it cost?

## A field note from the TechEquity v3 workshop on making AI infrastructure visible, governable, and optimizable.

---

In V1 we asked: can CoCo build a working AI agent in 60 minutes with 100 developers and a blank account?

In V2 we asked: can you wire that agent to Claude Code, Cursor, or any AI tool in the world?

V3 was always going to be the hard question. The one every enterprise team hits about three weeks after the demo:

**What does this actually cost to run?**

Last Thursday, August 20, at the TechEquity AI Infrastructure Forum, participants sat down with a live agent — or the `CHECKPOINTS.sql` path to restore one — and we added the governance layer. Step by step. In real time.

---

## The thing that happened two days before

On August 18, 2026 — two days before this workshop — Snowflake announced Dynamic Model Routing inside Cortex AI Gateway.

The short version: your agent now automatically routes simpler tasks to lighter, cheaper models. Reserving frontier models for complex reasoning. In one internal evaluation, agents using mixed open + proprietary models showed up to 3x greater token efficiency versus routing everything to the frontier.

Sridhar Ramaswamy put it simply: *"Usage is an input. The question that matters is what a company gets in return."*

We opened the session with that quote and asked a practical follow-up: could participants explain what their agent had cost to run? Without the right usage views, that answer is harder than it sounds.

V3 closes that gap in three moves: make usage visible, put controls around both credit currencies, and use the same tool that built the agent to find practical ways to operate it more efficiently.

---

## What changed from V2 to V3

V2 ended with GITTREND_MCP — a Snowflake-managed MCP Server that made your agent queryable from any MCP client in the world. One DDL statement. Your agent shows up in Claude Desktop, Cursor, VS Code.

V3 picks up exactly there. The agent is alive. The question is: what does it cost, and how do you keep it from surprising you?

Three things we added, in order:

**Step 4 — Cost Visibility**

Four ACCOUNT_USAGE views. Different latency, different granularity.

```
CORTEX_AI_FUNCTIONS_USAGE_HISTORY  — ≤5 min lag. Per user, per model, per function.
CORTEX_AGENT_USAGE_HISTORY         — up to 1 hr lag. Per agent, per user.
SNOWFLAKE_COWORK_USAGE_HISTORY     — up to 1 hr lag. CoWork sessions.
METERING_HISTORY                   — up to 3 hr lag. High-level summary.
```

One CoCo prompt runs all four. On a brand-new trial account, CORTEX_AI_FUNCTIONS_USAGE_HISTORY is the one with data first — your AI_COMPLETE calls from Steps 0–3 are already there within minutes, showing your username, the function, the model, and the credit cost.

The important moment is seeing real usage rather than a sample dashboard: a function call, its model, and its credit cost attached to the work you just performed.

**Step 5 — Cost Controls**

Two billing systems in one Snowflake account. Platform Credits (compute) and AI Credits ($2.00/credit flat since April 2026, edition-independent). Resource Monitors cover the first. They do not cover the second.

Three guardrails, one CoCo session:

1. **Resource Monitor** on WORKSHOP_WH — compute ceiling, suspend at 100%
2. **Account Budget** (`snowflake.local.account_root_budget`) — monthly limit on account-wide credit usage, including warehouse compute, AI services, and Cortex Search. No tag setup is required for the account budget.
3. **Per User AI Quota** — configured from Snowsight for AI-related features. It adds daily and monthly per-user limits with block enforcement.

The sequence matters: measure the workload first, then apply account-wide and per-user controls to the spend you can now see.

**Step 6 — Ask CoCo About the Cost**

This is the close-the-loop step. You built the agent. You measured it. You put guardrails on it. Then you ask the same tool that built it to optimize it.

The Cost Intelligence skill in CoCo queries CORTEX_AI_FUNCTIONS_USAGE_HISTORY, renders a daily cost chart inline, and gives you specific recommendations: reduce `max_results` on GITHUB_REPO_SEARCH, add a concise instruction to the system prompt, switch from `auto` to a specific model for simple queries.

These are practical levers you can apply without changing the agent's purpose.

Dynamic model routing is Snowflake doing this at the infrastructure layer automatically. Cost Intelligence is you doing it at the application layer deliberately. Both matter.

---

## What it actually costs

A workshop like this does not produce one universal cost number. Your result depends on warehouse size, query volume, search refreshes, selected models, and whether you are measuring a fresh account or an established workload.

What v3 gives you is a way to answer the question with your own data. `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` exposes AI function usage with short latency. `METERING_HISTORY` provides account-level context. Resource Monitors, Budgets, and Per User Quotas let you act on what you find.

The key is not a benchmark; it is visibility. You cannot optimize what you cannot measure, and you cannot govern what you cannot see.

---

## When it stopped feeling like a tutorial

Step 4, first result. CORTEX_AI_FUNCTIONS_USAGE_HISTORY came back with rows.

Not sample data. Your username. Your function calls. Your model. Your credits. Attached to the thing you built in the last 30 minutes.

Seeing those rows turns an abstract bill into an operational fact. That is the point: visibility is the prerequisite for everything else. You cannot optimize what you cannot measure. You cannot govern what you cannot see.

FinOps for AI is just FinOps. Same discipline, new services to track.

---

## Build it yourself

The workshop materials are available in the public repository:

**Workshop repo:** https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

`WORKSHOP-GUIDE-V3.md` walks through Steps 4–6. `CHECKPOINTS.sql` has fallback SQL for the v3 flow, including CP7, CP8, CP8b, and CP9. The `media/` folder has demo videos.

**Free trial:** https://signup.snowflake.com/

You need the V2 state before you start — either you ran it, or SETUP + CP1–CP6 in CHECKPOINTS.sql restores everything in about 7 minutes.

The same governance pattern works on any Snowflake-based agent: your support ticket classifier, your sales pipeline analyzer, your internal docs assistant. The GitHub dataset is the example. The pattern transfers.

---

## What's next: V4

A natural next question after Step 6 is: *can the agent govern itself?*

Not just CoCo making recommendations — but the agent embedding cost awareness into its own behavior. System prompts with budget constraints. Dynamic max_results based on query complexity. Agents that know they're operating inside a quota and route their own tool calls accordingly.

That's V4. Watch the repo.

If this was useful — ⭐ star the repo. Takes two seconds and helps others in the community find it.

https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

---

*[Richie Bachala](https://x.com/richiebachala) — Solutions Architecture @ Snowflake*

---

*#Snowflake #AIAgent #FinOps #CostManagement #CoCo #Cortex #MCP #ModelContextProtocol*
