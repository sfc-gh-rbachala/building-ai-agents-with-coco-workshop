# Workshop Levels

Three levels, one dataset, one repo. Each level builds on the previous.

---

## Level Comparison

| | v1 | v2 | v3 |
|---|---|---|---|
| **Guide** | [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md) | [`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md) | [`WORKSHOP-GUIDE-V3.md`](WORKSHOP-GUIDE-V3.md) |
| **Duration** | 60 min | 75 min | ~75 min |
| **MCP Server** | Take-home stretch | Live core step | Carried forward from v2 |
| **New this level** | GitTrend agent | MCP endpoint + external client | Cost visibility + controls |
| **Step structure** | 5 named steps | Step 0 / 1 / 2 (×5 sub-prompts) / 3 | v2 + Steps 4-6 |
| **Best for** | Mixed audiences, large rooms, 60 min slots | Technical audiences, 75 min slots | Infrastructure-focused audiences |
| **Checkpoints** | `CHECKPOINTS.sql` CP1–5 | `CHECKPOINTS.sql` CP1–6 | `CHECKPOINTS.sql` CP1–6 + v3 steps |

---

## What Each Level Delivers

### v1 — The 5-Step Pattern
*Guide: [`WORKSHOP-GUIDE.md`](WORKSHOP-GUIDE.md)*

Start here if: your room is large (50+), mixed technical levels, or you have a
60-minute slot.

Attendees leave with a working GitTrend agent in CoWork. MCP is explained and
given as a take-home stretch — no OAuth handshake required in the room.

```
Step 1  Set the context    AGENTS.md + CoCo CLI
Step 2  Load the data      107M GitHub events from public S3
Step 3  Explore & build    V_TRENDING_AI_REPOS view
Step 4  Add intelligence   AI_COMPLETE + Cortex Search Service
Step 5  Wire the agent     Cortex Agent = GitTrend
Stretch MCP Server         Take-home — exposes GitTrend to Claude/Cursor
```

### v2 — MCP Live
*Guide: [`WORKSHOP-GUIDE-V2.md`](WORKSHOP-GUIDE-V2.md)*

Start here if: your room is smaller and more technical, and you have 75 minutes.
First delivered at TechEquity AI Forum, Jul 28, 2026.

Steps 3–5 from v1 are compressed into a single rapid-fire block (5 sub-prompts).
That freed 15 minutes for the MCP Server step to be delivered live — attendees
leave with a working external endpoint they can query from Claude Desktop or Cursor.

```
Step 0  Set the context    AGENTS.md + CoCo CLI
Step 1  Load the data      107M GitHub events from public S3
Step 2  Build the agent    5 sub-prompts: explore → view → AI_COMPLETE → Search → Agent
Step 3  Wire MCP           CREATE MCP SERVER + OAuth + connect client
Run It  Query from MCP     Claude Desktop / Cursor / CoCo Desktop
```

### v3 — Cost Intelligence
*Guide: [`WORKSHOP-GUIDE-V3.md`](WORKSHOP-GUIDE-V3.md)*

Start here if: your audience cares about AI infrastructure economics and already
has v2 complete (or can restore from CHECKPOINTS.sql Checkpoint 6).

Builds directly on the live GitTrend agent. Adds cost visibility into the AI
infrastructure just built, then adds controls. First delivery: TechEquity AI
Infrastructure Forum, Aug 20, 2026.

Content under development — see the stub guide for the planned structure.

---

## Checkpoints

All levels share [`CHECKPOINTS.sql`](CHECKPOINTS.sql). It contains the fallback SQL
for every step across v1 and v2:

| Checkpoint | Covers | Guide step |
|---|---|---|
| SETUP | Database, warehouse, S3 load | v1 Step 2 / v2 Step 1 |
| CP1 | Schema exploration | v1 Step 3a / v2 Step 2① |
| CP2 | `V_TRENDING_AI_REPOS` view | v1 Step 3b / v2 Step 2② |
| CP3 | `AI_COMPLETE` summary | v1 Step 4a / v2 Step 2③ |
| CP4 | Cortex Search Service | v1 Step 4b / v2 Step 2④ |
| CP5 | GITTREND Agent | v1 Step 5a / v2 Step 2⑤ |
| CP6 | MCP Server + OAuth | v1 Stretch / v2 Step 3 |

v3-specific checkpoints will be added to `CHECKPOINTS.sql` during the v3 build
sprint.

---

## Lineage

| Version | Date | Venue | Attendees | Notes |
|---|---|---|---|---|
| v1 | Jun 30, 2026 | Snowflake SVAI Hub, Menlo Park | ~130 | Snowsight-first; no MCP |
| v2 | Jul 28, 2026 | Snowflake SVAI Hub, Menlo Park | — | CLI-first; MCP live |
| v3 | Aug 20, 2026 | Snowflake SVAI Hub, Menlo Park | — | Cost theme; under development |
