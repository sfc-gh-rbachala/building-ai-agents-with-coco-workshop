# Multi-Agent Demo — CoCo Desktop

Ask CoCo ordinary questions. It picks the multi-agent pattern itself.

```
AGENTS.md                 the lead's instructions: delegate, split, parallelize, merge
.cortex/agents/
  trend-analyst.md        claude-haiku-5-5    V_TRENDING_AI_REPOS
  cost-analyst.md         claude-haiku-5-5    ACCOUNT_USAGE metering (CP7)
  research-analyst.md     claude-sonnet-5-5   GITHUB_EVENTS + web search
```

Nothing new is deployed to Snowflake; the agents query the objects the workshop already
built. Your CoCo chat is the lead. `AGENTS.md` loads automatically, so you never have to
tell it to orchestrate.

## Setup (once)

1. Complete `CHECKPOINTS.sql` SETUP + CP2 (events loaded, `V_TRENDING_AI_REPOS`).
2. Enable web search: Snowsight » AI & ML » Agents » Settings » Web search.
3. **Open this repo folder as the CoCo Desktop workspace** (File » Open Folder), then
   start a **new session**. Check Settings » Agents (three agents) and Settings » Rules
   (`AGENTS.md`).

## The demo: three plain questions

**1. Routing.** One question, two specialists:

```
          "Top 3 agent repos, and what did this week cost?"
                              │
                              ▼
                     ┌──── CoCo (lead) ────┐
                     │  splits by intent   │
                     └──────┬───────┬──────┘
                   parallel │       │ parallel
                            ▼       ▼
                 trend-analyst     cost-analyst
                   (Haiku)           (Haiku)
                            │       │
                            ▼       ▼
                     ┌──── CoCo (lead) ────┐
                     │   merges answers    │
                     └─────────────────────┘
```

```
What are the top 3 trending agent repos, and what did this week cost me?
```
CoCo splits the question and sends `trend-analyst` and `cost-analyst` in parallel, then
merges their answers.

**2. Chain.** The second part depends on the first:

```
   "Hottest agent repo right now, and is it real or just hype?"
                              │
                              ▼
                         CoCo (lead)
                              │ step 1
                              ▼
                        trend-analyst ──────▶ "NousResearch/hermes-agent"
                                                        │ step 2
                                                        ▼
                                               research-analyst
                                              (Sonnet + web search)
                                                        │
                                                        ▼
                                                  CoCo (lead)
                                                  writes answer
```

```
What's the hottest agent repo right now, and is it actually being built or just hyped?
```
CoCo asks `trend-analyst` for the #1 repo, then hands that name to `research-analyst`.

**3. Fan-out.** The same job on many items:

```
      "Which of the top 5 trending repos are real vs. hype?"
                              │
                              ▼
                 CoCo (lead) ──▶ trend-analyst ──▶ top 5 repos
                              │
          ┌──────────┬──────────┼──────────┬──────────┐   all at once
          ▼          ▼          ▼          ▼          ▼
      research   research   research   research   research
       repo 1     repo 2     repo 3     repo 4     repo 5
          │          │          │          │          │
          └──────────┴──────────┼──────────┴──────────┘
                              ▼
                         CoCo (lead)
                     merges 5 verdicts
```

```
Which of the top 5 trending repos are real projects versus hype?
```
CoCo gets the top 5 from `trend-analyst`, runs 5 `research-analyst`s in parallel, and
merges their verdicts.

None of these prompts names a pattern. The question decides the shape.

## What to look for

- **The plan.** CoCo says what it's about to do ("first get the top 5, then deep-dive
  each in parallel") before it starts any specialist.
- **The specialist list** at the end of each answer: who was asked what.
- **Model tiers.** Settings » Agents: Trend and Cost run on Haiku, Research on Sonnet.
- **AGENTS.md is the contract.** `AGENTS.md` (how the lead works) plus each agent file
  (scope, query, output shape) is the whole system.
