# Workshop Guide — v3
## Cost Intelligence: Know What Your Agent Actually Costs

**This is the v3 guide.** It builds on the GitTrend agent from v2
([`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md)) and adds a cost intelligence layer —
so you can understand, measure, and optimize the cost of the AI infrastructure you
just built.

**Pre-requisite:** Complete v2 (GitTrend agent + MCP Server built and working) or
start from [`CHECKPOINTS.sql`](CHECKPOINTS.sql) Checkpoint 6 to restore the full
v2 state.

See [`VERSION.md`](VERSION.md) for the level comparison.

---

> **Content under development** for TechEquity AI Infrastructure Forum,
> August 20, 2026. This guide will be complete before the event.
>
> Theme: **Cost** — understanding, measuring, and optimizing the cost of
> AI agents built on Snowflake.

---

## What v3 Adds

Starting from a live GitTrend agent with an MCP endpoint, v3 addresses the question
every engineering team asks after shipping: *"What does this actually cost, and how
do I control it?"*

**Planned additions** (details to be finalized):

- **Step 4 — Cost Visibility:** query `ACCOUNT_USAGE` and `METERING_HISTORY` to
  see exactly what your AI build cost — by warehouse, by Cortex function, by
  agent run.
- **Step 5 — Cost Controls:** set resource monitors, warehouse auto-suspend
  policies, and budgets. Attach them to `WORKSHOP_WH` and see the guardrails in
  action.
- **Step 6 — Cost-Aware Agent:** add a cost context to GitTrend's system prompt
  and surface Cortex AI credit consumption as part of the agent's answers.

---

## Facilitator Notes (placeholder)

- Target audience: technical, infrastructure-focused
- Estimated duration: TBD (75 min expected, based on v2 slot)
- MCP: carried forward from v2 (already live)
- New Snowflake objects: TBD

---

## Resources

- [Snowflake Cost Management docs](https://docs.snowflake.com/en/user-guide/cost-understanding-overall)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Snowflake Budgets](https://docs.snowflake.com/en/user-guide/budgets)
- [Cortex AI cost and credit usage](https://docs.snowflake.com/en/user-guide/cost-understanding-compute-credit#cortex-functions)
- [Workshop repo](https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop)
