# Events

Each file here holds the details for one live delivery: date, venue, signup link, timing, and anything specific to that room.

The build itself lives in [`../WORKSHOP-GUIDE.md`](../WORKSHOP-GUIDE.md) and doesn't change between events.

| Event | Date | Format | Status |
|---|---|---|---|
| [ODSC AI × Snowflake, San Francisco](odsc-2026-08-06.md) | 2026-08-06 | 5 steps live, MCP as take-home | **Upcoming** |
| [TechEquity AI Forum, Level 2](techequity-2026-07-28.md) | 2026-07-28 | 6 steps live, MCP included | Past |

Attendee-facing comms for each event (pre-workshop email, reminders, social posts) live alongside the event file — see [`odsc-2026-08-06-comms.md`](odsc-2026-08-06-comms.md).

---

## Running this yourself?

Copy an existing event file as a starting point and fill in:

1. **Date, time, venue** — and the walk-in / networking blocks if the host has them
2. **Trial signup link** — generate a fresh event link; note its **UTC activation window** prominently. This is the single most common attendee failure: signing up too early gets them a trial without AI features.
3. **Timing map** — how the 5 steps fit your actual slot length. 60 minutes is tight but workable. Under 45, cut Step 4a (the `AI_COMPLETE` summary) and go from the view straight to Cortex Search and the agent. **Do not cut Cortex Search** — it's the agent's only data tool, so removing it leaves you with an agent that can't answer anything.
4. **Level** — sets how much you explain vs. how fast you move
5. **MCP: live or take-home** — needs ~20 extra minutes and an OAuth handshake per attendee. Take-home is the safe call for large or mixed-level rooms.

Then add a row to the table above and to the table in the root [`README.md`](../README.md).
