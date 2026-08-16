# TechEquity AI Infrastructure Forum

**Thursday, August 20, 2026 | 3:00–8:30 PM PT**
**Snowflake SVAI Hub, 8th Floor, 135 Constitution Dr, Menlo Park, CA 94025**

*Foundation to Intelligence Series — v3: Cost Intelligence*
Facilitated by **Richie Bachala**, Solutions Architecture Leader, Snowflake.

**Level:** v3 | **Guide:** [`../WORKSHOP-GUIDE-V3.md`](../WORKSHOP-GUIDE-V3.md)

**Luma:** https://luma.com/aug-ai-forum

---

## Pre-Work

### 1. Get a Snowflake trial account

Use the event-specific link below. It activates the AI features this workshop
needs, and only for accounts created inside the activation window.

> **Trial link:** https://signup.snowflake.com/?t=f128a8bcb25e35b4e1c114eb153493ac08611899e5ef34d114ca9340ff9ca616&cloud=aws&region=us-east-2
> **Activation window:** Aug 18–23, 2026 (UTC) — accounts created outside this
> window are plain trials without AI features.

@snowflake.com emails are exempt from the window (useful for testing).

**What the link prefills:** Enterprise edition, AWS, and a region with full Cortex
AI access. Do not change these during signup — changing the region removes AI
features.

> **Known friction at signup:** a cookie consent banner may cover the Sign Up
> button until dismissed; reCAPTCHA appears on submit. Expected and normal.

### 2. Install the CoCo CLI

```bash
# macOS / Linux / WSL
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh

# Windows (PowerShell)
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

Confirm: `cortex --version`

---

## Workshop Slot

| Time | Block |
|---|---|
| 3:00–3:30 PM | Registration + networking |
| 3:30 PM onward | Talks + concurrent workshops begin |
| ~7:10 PM PT | **Workshop: Foundation to Intelligence v3** (estimated start — confirm with TechEquity) |
| ~8:10 PM PT | Wrap |
| 8:15–8:30 PM | Closing |

This is a multi-track event. The workshop runs concurrently with keynotes in the
meetup room. Estimated slot: ~60 min build (possibly 75 min — confirm with
TechEquity Ai before finalizing the guide pacing).

---

## Format

**Pre-requisite:** v2 complete (GitTrend agent + MCP Server built and working),
or restore from `CHECKPOINTS.sql` Checkpoint 6.

**Theme:** Cost intelligence — understand, measure, and control the cost of the
AI infrastructure you built in v2.

Detailed step structure is in [`../WORKSHOP-GUIDE-V3.md`](../WORKSHOP-GUIDE-V3.md)
(under development — will be finalized before Aug 18).

| Step | What | Duration |
|---|---|---|
| 0 | AGENTS.md + CLI context | ~10 min |
| 1 | Load data / restore from CP6 | ~7 min |
| 2 | Build GitTrend agent (v2 fast replay) | ~10 min |
| 3 | MCP Server (v2 carried forward / verify active) | ~5 min |
| 4 | Cost visibility (new) | TBD |
| 5 | Cost controls (new) | TBD |
| 6 | Cost-aware agent (new) | TBD |
| — | Run It | ~8 min |

---

## Audience

612 registered as of Aug 12. In-person + online livestream.

- Infrastructure builders and platform engineers
- Developers and engineers exploring applied AI and agent-based systems
- Startup founders building AI-powered products
- Technical career-transition professionals

More technical on average than ODSC Aug 6 (~100, mixed levels). Comparable to
TechEquity Jul 28 in technical depth.

---

## Event Program Context

Richie's workshop runs in the **Workshop Room** concurrent with other talks in the
Meetup Room. Key session to note for facilitator notes in the guide:

- *"What Breaks When Agents Start Taking Actions on Behalf of Users"* —
  Ravi Madabhushi, Scalekit. This is the security keynote. Mention it during
  Step 3 when discussing the MCP endpoint: *"You just built the endpoint the
  security session was about."*

---

## Logistics

- **Arrival guide:** https://bit.ly/SVAI-Arrival-Guide
- **Parking:** self-park in the garage next to the 135 Building
- **Wi-Fi:** SVAI Hub has handled 100+ attendees before — heaviest workshop step
  (S3 load) runs server-side, so bandwidth load is mostly prompt traffic
- **Deck:** needs to be updated from Jul 28 version — change date, update
  speaker reference from Saurabh → Ravi Madabhushi on Step 3 facilitator note

---

## Comms Checklist

- [x] Trial link generated (window: Aug 18–23 UTC)
- [ ] Pre-event email to registrants (send Aug 18–19)
- [ ] LinkedIn post
- [ ] Day-of reminder (morning of Aug 20)
- [ ] Deck updated (date + speaker ref)
- [ ] WORKSHOP-GUIDE-V3.md content finalized
- [ ] v3 build tested on a fresh trial account

---

*This is a public event. If you attended and are looking for resources, the workshop
guide is at [`../WORKSHOP-GUIDE-V3.md`](../WORKSHOP-GUIDE-V3.md) and all fallback
SQL is in [`../CHECKPOINTS.sql`](../CHECKPOINTS.sql).*
