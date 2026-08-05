# ODSC Aug 6 — Attendee Communications

Copy-paste ready. Three assets:

1. **Pre-workshop email** — send **Wednesday Aug 5** via Luma (ODSC owns the registrant list)
2. **Day-of reminder** — optional short version, morning of Aug 6
3. **Public post** — LinkedIn / Slack, for people not on the Luma list

> **Why Aug 5 and not earlier:** the trial link only activates AI features for accounts created **Aug 4–9 UTC**. Emailing before Aug 4 causes attendees to sign up too early and show up with a trial that can't run the workshop. Aug 5 is the safe send date.

---

## 1. Pre-Workshop Email — send Wed Aug 5

**Send via:** Luma event page → Guests → Email attendees (ODSC hosts: Elen G, Paula Micetic, Julia Voichuk, Ira Pidkovych)

**Subject:** `5 minutes of prep for tomorrow's AI agent build (please do this tonight)`

**Preview text:** `Two setup steps so you're building, not installing, at 6:30.`

---

Hi —

You're registered for **Build an AI Agent in <60 Min** tomorrow evening at Mindspace SF. This is a hands-on build, not a demo you watch, so there are **two setup steps to do before you arrive.** They take about five minutes total.

If you skip them, you'll spend the first 20 minutes installing while everyone else is building.

**Step 1 — Create your Snowflake trial account (do this today, not earlier)**

Use this event-specific link:

https://signup.snowflake.com/?t=ce05e6656e36201a16f56b4a1ae0135d4a0055666ed80498b700c4d33393e867&cloud=aws&region=us-east-2

Good news — the link already fills in the right edition (Enterprise), cloud (AWS), and region (US East / Ohio). **Leave those as they are.** Changing the region or edition is the one thing that breaks the AI features we need. You just fill in name, work email, company, and job title.

Two small snags to expect: the cookie banner covers the Sign up button until you dismiss it, and there's a reCAPTCHA on submit.

**Important:** this link only switches on the AI features we need for accounts created **August 4–9**. If you already made a Snowflake trial earlier than that, please create a fresh one with this link — an older trial will be missing what we use.

**Step 2 — Install the CoCo CLI**

We're working in the terminal, not a web UI.

macOS / Linux / WSL:
```
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

Windows (PowerShell):
```
irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex
```

Then confirm it worked:
```
cortex --version
```

If that prints a version number, you're ready.

**What we're building**

An AI agent on **107 million real GitHub events**, starting from a completely empty Snowflake account. You'll be able to ask it things like *"what's the fastest-growing AI project this month?"* and get an answer grounded in actual data, not a model's training memory.

You will not write SQL by hand. CoCo writes it; you direct it.

The five-step pattern you'll learn works on any dataset — your support tickets, your sales pipeline, your product telemetry. That's the part worth taking back to work.

**Materials**

Everything is here, including the full guide and fallback SQL for every step:
https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

Your event page with timing and logistics:
https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop/blob/main/events/odsc-2026-08-06.md

**Logistics**

- **Thursday, August 6** — doors and food at 6:00 PM, workshop starts **6:30 PM sharp**
- **Mindspace, 575 Market St, San Francisco**
- **Bring your laptop and charger.** Venue Wi-Fi will be shared by around 100 people, so a phone hotspot is a smart backup.

Hit reply if you get stuck on either setup step — much easier to sort out tonight than at 6:30 tomorrow.

See you there,

**Richie Bachala**
Solutions Architecture Leader, Snowflake
https://www.linkedin.com/in/richiebachala/

---

## 2. Day-Of Reminder — morning of Aug 6 (optional)

**Subject:** `Tonight, 6:30 PM — quick setup check`

---

Quick check before tonight's AI agent build at Mindspace:

1. **Snowflake trial created with the event link?** (must be created Aug 4 or later — and leave the prefilled edition and region as they are)
   https://signup.snowflake.com/?t=ce05e6656e36201a16f56b4a1ae0135d4a0055666ed80498b700c4d33393e867&cloud=aws&region=us-east-2

2. **`cortex --version` prints a version number?**
   Install: `curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh`
   (Windows: `irm https://ai.snowflake.com/static/cc-scripts/install.ps1 | iex`)

3. **Laptop and charger packed?**

Not done yet? Do it on the train — takes five minutes and means you're building at 6:30 instead of installing.

Doors and food at 6:00. Workshop starts 6:30 sharp.
575 Market St, SF.

Guide and fallback SQL: https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

See you tonight,
Richie

---

## 3. Public Post — LinkedIn / Slack

**For LinkedIn (post Aug 5):**

Tomorrow evening in San Francisco: building a production AI agent on 107 million real GitHub events, starting from a completely empty Snowflake account. In under an hour, hands-on.

I'm running this with ODSC AI at Mindspace on Market St. Doors at 6, build starts 6:30.

The premise: general-purpose AI coding tools start blind to your schemas, roles, and warehouses. They burn time and tokens interrogating you before they can build anything. CoCo starts with your data context already in hand — and you feel the difference in the first five minutes.

Five steps. No SQL written by hand. The pattern transfers directly to your own data on Monday.

Registered attendees: check your email for the two setup steps — trial account and CLI install, about five minutes. Please do them tonight rather than at the venue.

Everything is public, including fallback SQL for every step if you want to follow along from anywhere:
https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

Event details: https://luma.com/odscai-imyl

---

**For Slack / Discord (shorter):**

Running a hands-on workshop with ODSC AI tomorrow in SF — build an AI agent on 107M real GitHub events from an empty Snowflake account, under an hour, no hand-written SQL.

Thu Aug 6, doors 6:00 / build 6:30, Mindspace 575 Market St.
Details: https://luma.com/odscai-imyl
Materials (public, follow along from anywhere): https://github.com/sfc-gh-rbachala/building-ai-agents-with-coco-workshop

Coming? Two setup steps beforehand — Snowflake trial via the event link, and `curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh`. Five minutes.

---

## Send checklist

- [x] Trial link verified — page loads clean, Enterprise + AWS + US East (Ohio) all prefilled by the token, no toggle to click
- [ ] Confirm ODSC hosts can send to registrants, and who is pressing send
- [ ] Pre-workshop email sent **Aug 5**
- [ ] Repo pushed and public before the email goes out — the email links to it
- [ ] LinkedIn post live Aug 5
- [ ] Day-of reminder queued for the morning of Aug 6
