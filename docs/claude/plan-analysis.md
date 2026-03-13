# Planning Process Analysis: Cross-Agent Comparison

## Overview

All three agents agree on the core SDD lifecycle: **specify → plan → tasks → implement**, and all recognize the existing Speckit toolchain. But they differ significantly in scope, tone, and emphasis.

---

## Claude (`docs/claude/planning-process.md`)

**Style**: Project plan / implementation guide
**Audience**: Team adopting the process for the first time

**Distinctive features:**

- Frames the document as a *plan to establish the process* (meta-level), with Goals, Non-Goals, Risks, and Acceptance Criteria
- Most detailed on the Speckit command inventory — full table with all 9 commands
- Explicitly calls out the **Constitution** as step zero, with a hard blocker if it's missing
- Includes a **Risks & Mitigations** table (6 risks identified)
- Has **Open Questions** with TBD owners, acknowledging governance gaps
- Defines the MVP checkpoint as a "hard stop, not advisory"
- Notes size thresholds for when a spec is optional

---

## Gemini (`docs/gemini/planning-process.md`)

**Style**: Conceptual explainer / methodology overview
**Audience**: Anyone new to SDD, including non-engineers

**Distinctive features:**

- Most accessible/educational — explains *why* SDD works before describing *how*
- Only document with a dedicated section on **AI agent synergy**, arguing that clear specs reduce hallucinations
- Lightest on process enforcement — no gates, no approval steps, no governance
- Aligns each phase to Speckit tooling, but descriptively rather than prescriptively
- Shortest and most readable of the three

---

## Codex (`docs/codex/planning-process.md`)

**Style**: Engineering process specification / policy document
**Audience**: Implementing engineers and coding agents

**Distinctive features:**

- Most **operationally rigorous** — reads like a team charter or runbook
- Introduces **Intake & Classification** as a distinct phase (unique among the three), with 5 change types that determine planning depth
- Introduces a formal **Review phase** (step 6) — the only document to describe PR review as part of the lifecycle
- Uses the **CTR method** (Context → Task → Refine) for planning — a concrete framework absent in the others
- Most explicit about **testing**: requires an explicit test matrix in every plan, lists 6 coverage categories, treats test intent as part of planning not implementation
- Explicit **ADR trigger conditions** — the most detailed treatment of when architectural decisions need formal documentation
- Ends with a frank assessment of the repo's current state: constitution is a placeholder, governance is incomplete

---

## Key Differences at a Glance

| Dimension | Claude | Gemini | Codex |
|---|---|---|---|
| Tone | Project plan | Conceptual guide | Policy/runbook |
| Phases | 5 (spec→implement) | 5 (spec→implement) | 6 (adds Review) |
| Intake/classification | No | No | Yes |
| Review phase | No | No | Yes |
| Constitution emphasis | Strong (step zero) | Implicit | Strong (noted as incomplete) |
| Testing requirements | Optional/TBD | Mentioned | Required, typed |
| ADR guidance | None | None | Explicit trigger conditions |
| AI agent focus | None | Dedicated section | Implicit (written for agents) |
| Governance/approvals | Open questions | None | 7 formal gates with tech lead approval |
| Risks & mitigations | Yes (table) | No | No |

---

## Summary

- **Gemini** is the best entry point for understanding *why* SDD matters
- **Claude** is best for *adopting* the process — it's a plan for the plan, with clear goals and risks
- **Codex** is best as an *operational reference* — most complete on governance, testing, and day-to-day execution rules

The most notable gap across all three: none define a concrete size threshold for when specs are optional, and none address post-deployment concerns. Codex is the only one that calls out the current state of the repo honestly (constitution placeholder = incomplete governance).
