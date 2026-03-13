# Review Process Proposal: The Torvalds Standard

## Philosophy

The review process is the final and most critical gate in the Archive Agentic workflow. It is not a formality; it is a rigorous technical interrogation. We adopt the "Torvalds Standard": if a change is not technically superior, maintainable for a decade, and perfectly aligned with the project's soul, it is rejected.

Review is where we stop "good enough" from polluting the codebase. We value:

- **Correctness over speed.**
- **Clarity over cleverness.**
- **Proven reliability over theoretical elegance.**
- **Absolute traceability** from business intent to every line of code.

## The Review Lifecycle

A review is only complete when all four tiers of validation are satisfied.

### Tier 1: Automated Validation (The Prerequisites)

Before a human or senior agent even looks at the code, the PR must prove its basic viability.

- [ ] **CI Pass:** Build, Lint, and Type-check must pass with zero warnings.
- [ ] **Test Suite:** 100% of the existing suite must pass.
- [ ] **New Tests:** The specific tests defined in `plan.md` must be present and passing.
- [ ] **Traceability:** The PR must link to the specific `spec.md`, `plan.md`, and `task.md` it implements.

### Tier 2: Implementation Fidelity

We verify that the code does *exactly* what the plan said it would do—no more, no less.

- **Goal Alignment:** Does this solve the specific task in `tasks.md`?
- **Scope Discipline:** Did the implementer resist "speculative cleanup" or unrelated refactoring?
- **TDD Evidence:** Is there proof (e.g., in the execution log) that a failing test preceded the implementation?

### Tier 3: Architectural Integrity (The Torvalds Core)

This is the technical heart of the review. We ask the hard questions:

- **Clean Abstractions:** Does this introduce "spaghetti" logic, or does it cleanly separate concerns?
- **Performance & Scalability:** Will this implementation fail under load or with edge-case data?
- **Side Effects:** Does this change have hidden impacts on other subsystems?
- **Future Debt:** Is this a "quick fix" that we will have to rewrite in six months?
- **The "Why":** If the implementation differs from the plan, is the justification technically sound and documented?

### Tier 4: The Final Polish

- **Naming:** Are variable, function, and file names descriptive and idiomatic?
- **Documentation:** Is the code self-documenting, and are complex algorithms explained?
- **Types:** Are types as narrow and descriptive as possible? (Avoid `any` or overly broad interfaces).

---

## The "Torvalds" Review Checklist

Every reviewer must be able to answer "Yes" to these questions before approving:

1. **Is this the simplest way to solve the problem?** (Avoid over-engineering).
2. **Does the reviewer *truly* understand what every line does?** (No "magic" code).
3. **Are the edge cases handled, or just the "happy path"?**
4. **If this code breaks at 3 AM, can an engineer diagnose it quickly?** (Observability/Logging).
5. **Does it follow the project Constitution?** (Engineering principles).

---

## Feedback & Revision Protocol

Review is a technical dialogue, not a personal critique.

- **Constructive but Blunt:** If code is bad, say it is bad and explain *why* technically.
- **No Negotiating on Quality:** If a change introduces debt or risk, it must be fixed. "We'll fix it in a follow-up" is generally rejected unless tracked by a specific P1 task.
- **The Re-Review:** Any change made in response to a review requires a full re-run of Tier 1 (Automated Validation).
- **Agent Handoff:** If an agent receives review feedback, it must document its understanding of the critique before attempting the fix.

---

## Agent-Specific Review Rules

When agents are involved in the review process (as authors or reviewers):

1. **Peer Review:** Agents should review each other's work before a human is involved, checking for common agent errors (hallucinations, missing edge cases).
2. **Execution Logs:** Reviewers must check the agent's `## Execution Log` in the GitHub Issue to verify the *process* was followed (e.g., failing test first).
3. **No Blind Approval:** A human or a "Senior Reviewer" agent must perform the final Tier 3 (Architectural) and Tier 4 (Polish) checks.

---

## Definition of Done for Review

A PR is "Review Done" when:

1. All Tier 1-4 checks are checked off.
2. All reviewer comments are addressed and resolved.
3. The "Torvalds" checklist is satisfied.
4. Final validation evidence (logs, screenshots, CI links) is attached.
5. The reviewer issues an explicit `Approved` status.

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
| :--- | :--- | :--- |
| "Rubber stamp" approvals | High | Require at least two reviewers for core architectural changes; use a checklist. |
| Review delays implementation | Medium | Keep tasks small (1 task = 1 PR) so review is fast and focused. |
| Emotional friction from blunt feedback | Medium | Maintain professional, technical focus; separate the code from the person. |
| Agents missing subtle architectural flaws | High | Final architectural gate must be passed by a human or a specialized "Architect" agent. |

---

## Next Steps

1. Adopt this proposal as the project standard via an ADR.
2. Incorporate the checklist into the PR template.
3. Assign specific "Maintainer" roles (human or agent) for Tier 3/4 reviews.
