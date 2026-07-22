---
name: weekly_digest
description: >
  Generate a structured weekly GitHub trending digest when the user asks for a
  "weekly digest", "trending report", "newsletter", or "what's hot this week".
  Produces a multi-category report covering AI/ML, infrastructure, and developer tools.
---

# Weekly Digest Skill

## When to Use

Invoke this skill when the user asks for:
- A weekly digest or trending report
- A newsletter or summary of what's hot
- A category-by-category breakdown of trending repos

## Instructions

1. Search for top repos in each of these categories separately:
   - **AI/ML**: repos related to machine learning, LLMs, agents, GPT, neural networks
   - **Infrastructure**: repos related to cloud, Kubernetes, databases, DevOps
   - **Developer Tools**: repos related to IDEs, CLI tools, testing, build systems
2. For each category, list the top 3 repos with star counts in owner/repo format
3. Mark any repo that appears to be new or gaining stars unusually fast with a "🚀 Breakout" tag
4. Format the output with category headers and bullet points
5. End with a one-sentence "Signal of the Week" that captures the most interesting pattern

## Output Format Example

### AI/ML
- **owner/repo** — 2,400 stars — Brief note on what it does
- **owner/repo** — 1,800 stars
- **owner/repo** — 1,200 stars 🚀 Breakout

### Infrastructure
...

### Developer Tools
...

**Signal of the Week:** One sentence about the dominant theme or surprise.
