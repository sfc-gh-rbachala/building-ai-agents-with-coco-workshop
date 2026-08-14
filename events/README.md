# Events

Each file here holds the details for one live delivery: date, venue, signup link,
timing, level, and anything specific to that room.

The build guides are in the repo root — which guide an event uses depends on its
level. See [`../VERSION.md`](../VERSION.md) for the full comparison.

| Event | Date | Level | Guide | Format | Status |
|---|---|---|---|---|---|
| [TechEquity AI Infrastructure Forum](techequity-2026-08-20.md) | 2026-08-20 | v3 | [WORKSHOP-GUIDE-V3.md](../WORKSHOP-GUIDE-V3.md) | Cost Intelligence + MCP | **Upcoming** |
| [ODSC AI × Snowflake, San Francisco](odsc-2026-08-06.md) | 2026-08-06 | v1 | [WORKSHOP-GUIDE.md](../WORKSHOP-GUIDE.md) | 5 steps, MCP take-home | Past |
| [TechEquity AI Forum, Level 2](techequity-2026-07-28.md) | 2026-07-28 | v2 | [WORKSHOP-GUIDE-V2.md](../WORKSHOP-GUIDE-V2.md) | 4 blocks, MCP live | Past |

Attendee-facing comms for each event (pre-workshop email, reminders, social posts)
live alongside the event file — see [`odsc-2026-08-06-comms.md`](odsc-2026-08-06-comms.md).

---

## Running this yourself?

Copy an existing event file as a starting point and fill in:

1. **Date, time, venue** — and the walk-in / networking blocks if the host has them
2. **Trial signup link** — generate a fresh event link; note its **UTC activation
   window** prominently. This is the single most common attendee failure: signing up
   too early gets them a trial without AI features.
3. **Level** — choose v1 (60 min, MCP take-home), v2 (75 min, MCP live), or v3
   (75 min, cost theme, pre-req: v2). See [`../VERSION.md`](../VERSION.md).
4. **Guide** — link to the guide that matches the level
5. **Timing map** — how the steps fit your actual slot length.
   - Under 60 min: use v1, cut Step 4a (`AI_COMPLETE`) if needed. **Do not cut
     Cortex Search** — it's the agent's only data tool.
   - 60-75 min: v1 with MCP take-home, or v2 if the room is technical.
   - 75+ min: v2 or v3.
6. **MCP: live or take-home** — needs ~18-20 extra minutes and an OAuth handshake
   per attendee. Take-home is the safe call for large or mixed-level rooms.

Then add a row to the table above. This file is the canonical event log — the root README points here.
