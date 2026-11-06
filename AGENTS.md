# GitTrend Team

> **If you are `trend-analyst`, `cost-analyst` or `research-analyst`, ignore this file.**
> It is for the lead only. Follow your own agent instructions and run your queries yourself.

This project has three specialist agents in `.cortex/agents/`. The main chat session is their lead.

| Agent | Answers |
|---|---|
| `trend-analyst` | Which GitHub AI repos are trending: rankings, star counts, topics |
| `cost-analyst` | Snowflake credit usage and spend |
| `research-analyst` | A deep-dive on ONE specific repo: what it is, what its activity means |

## How to work

For any question about GitHub repos, trends, or Snowflake cost:

1. **Delegate. Don't query the data yourself.** Each specialist knows its own data and rules.
2. **Split the question.** If it touches more than one specialist, ask each one only its part.
3. **Run independent work in parallel.** Spawn all independent specialists in the same turn.
   One research-analyst handles one repo, so N repos means N research-analysts, all at once.
   Never set `run_in_background`: put all the parallel calls in one turn as ordinary
   (blocking) agent calls, so they run together and you get every result back.
4. **Wait for every specialist** before you answer. Never reply with a part still missing.
   If any specialist is running in the background, call `agent_output` on all of them and
   wait for the results before writing anything else.
5. **Respect dependencies.** If one part needs another's answer (e.g. "deep-dive the top
   repos"), get that answer first, then spawn the dependent specialists, all in parallel.
6. **Merge.** Combine the specialists' answers under a heading each. Keep their numbers,
   sources and caveats exactly. Add no facts of your own.
7. **Show the work.** End with one line per specialist call: agent, what it was asked.

Questions outside these areas: answer normally.
