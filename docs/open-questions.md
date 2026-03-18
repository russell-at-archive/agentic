# Open Questions

Consolidated from open question sections in process documents and agent doc reviews.
Questions are deduplicated, grouped by theme, and assigned stable identifiers.

**Sources**: `agentic-team.md`, `planning-process.md`, `implementation-process.md`,
`review-process.md`, `tracking-process.md`,
`docs/claude/docs-review-2026-03-16.md`, `docs/codex/docs-review-2026-03-16.md`,
`docs/gemini/review.md`

---

## Governance & Constitution

**OQ-01** — Who has authority to approve and ratify the Constitution, and what is the
deadline for doing so? The Constitution is declared a blocker for all feature planning
in `planning-process.md` Phase 0.

**OQ-02** — Which of the nine ADRs in the `agentic-team.md` backlog must be written first
to unblock implementation sequencing? Is there a sequencing dependency among them?

**OQ-03** — Should `agentic-team.md` itself be elevated to an ADR, or should it produce
individual ADRs for each architectural decision it contains? What is the approval path
for moving it from Draft to ratified status, and who are the required approvers?

---

## Agent Roles & Dispatch

**OQ-04** — Who has final authority to approve the plan artifact when the issue is in `In Review` + `plan` label state?
Is it always a human? Can the Technical Lead serve as plan reviewer in addition to code
reviewer? One document assigns ownership to `Architect`; another assigns it to `Human`.
These must be reconciled.

**OQ-05** — Can multiple Engineer agents work simultaneously on independent tasks within
the same feature? If so, what is the worktree and branch naming policy, and how are lock
conflicts detected and resolved?

**OQ-33** — Should `/speckit.draft` be the canonical operator interface for the
Feature Draft Agent, or should direct runtime invocation remain sufficient?

**OQ-34** — Should the Draft Design Prompt live only in Linear, or also be
persisted in the repository after issue creation?

**OQ-35** — What minimum quality bar must the Feature Draft Agent enforce before
creating a `Triage` issue?

**OQ-36** — Who is the requestor of record when intake starts from an automated
source rather than a named human stakeholder?

---

## Tooling & Infrastructure

**OQ-07** — What is the canonical local validation command for this repository? It should
be a single invocable command (e.g., `make validate`, `just check`) defined in the project
`Makefile` or equivalent, referenced explicitly in `implementation-process.md`.

**OQ-08** — Is the Director designed to run as a daemon (low latency, higher operational
complexity) or as a scheduled job (simpler to operate and audit)? The choice affects
infrastructure requirements, failure surface area, and polling interval.

**OQ-09** — Which AWS operations are agents expected to perform — infrastructure
provisioning, secrets retrieval, deployment, or some subset? Which agent owns each
category of AWS operation?

**OQ-10** — Should `/speckit.taskstoissues` be removed from the planning workflow entirely,
retained only as a GitHub-fallback when Linear is unavailable, or replaced with a
Linear-native step? Its current presence creates a parallel issue tracker that conflicts
with the Linear-first tracking model.

**OQ-11** — Should there be a project-local `skills/` directory in this repo, or should
`~/.agents/AGENTS.md` be updated to reference the global `~/.agents/skills/` path? The
current mandate requires local skills but no local `skills/` directory exists.

**OQ-12** — Is the Graphite CLI (`gt`) authenticated and available in agent execution
environments? Is there a Linear CLI authenticated for this repository, or do agents
interact with Linear through its API directly?

---

## Process: Validation & Quality Gates

**OQ-13** — What is the merge gate policy when local validation passes but CI fails due to
environment differences? Is CI failure an independent merge blocker regardless of local
validation outcome?

**OQ-14** — Are coverage thresholds enforced as part of the local validation gate, or is a
passing test suite sufficient? If thresholds are enforced, what are they and where are
they configured?

**OQ-15** — Who has authority to approve exceptions to any mandated process step (e.g.,
no-TDD waiver, skip-review for trivial changes), and where must that approval be recorded
— in the Linear issue, the PR, or an ADR?

---

## Process: Planning

**OQ-16** — What is the size or complexity threshold below which a formal spec is optional?
Is there a class of work (chore, trivial bug fix) that may bypass Phase 1–2 of the
planning process?

**OQ-17** — Should tests be mandatory for MVP tasks even if current spec templates mark
some tests as optional? Is there a test tier below which automation is explicitly waived?

---

## Process: Implementation

**OQ-18** — Should Graphite stack names follow a naming convention tied to the feature or
spec identifier (e.g., `spec-###-<slug>`)? What is the maximum allowed stack depth before
a forced split is required? Current guidance gives three to four frames as a soft cap.

**OQ-19** — What is the approved procedure when TDD is not technically feasible (e.g.,
pure infrastructure tasks or third-party integration bootstrapping)? Should acceptance
tests substitute for unit tests, and who approves the exception?

---

## Process: Human Interaction

**OQ-20** — How are agents notified that a human has approved a gate (spec review, plan
review)? What is the signal mechanism — a Linear state change, a PR approval, a comment
keyword, or something else?

**OQ-21** — What is agent behavior while waiting for human approval: polling interval,
timeout duration, and escalation path if no response is received within a defined window?

---

## Documentation Housekeeping

**OQ-22** — Should `docs/README.md` enforce strict link coverage for all active process
documents? It currently omits `docs/agentic-team.md`, the most complete operational
specification.

**OQ-23** — Should the open question sections embedded in `agentic-team.md`,
`planning-process.md`, and `implementation-process.md` be removed and replaced with
references to this file once questions are resolved? Keeping parallel lists risks divergence.

---

## Misalignments Across Documents

**OQ-24** — Gate T-5 is defined inconsistently across documents. `agentic-team.md` requires
"ticket lock acquired; worktree created; stack initialized" while `tracking-process.md` requires
only "worktree created; Graphite stack initialized; issue updated" with no mention of ticket lock
acquisition. Should T-5 in `tracking-process.md` be updated to include the ticket lock step, or
should the ticket lock requirement be removed from `agentic-team.md`?

**OQ-25** — `review-process.md` defines service level targets (first review within one business
day for standard PRs, two for high-risk) but these are absent from `tracking-process.md`'s
operating cadence. Should SLAs be canonicalized in one document and referenced by the others?

**OQ-26** — `implementation-process.md` Step 7 (Merge) uses `gt submit --stack` as the merge
command, which is the same command used in Step 5 to open the PR. Is this intentional, or should
the merge step reference a different command (e.g., `gt land`, merge via the Graphite dashboard,
or a specific squash strategy)?

---

## Documentation Structure

**OQ-27** — `review-process.md` is the only process document with no cross-reference to
`docs/open-questions.md` and no open questions section. Should a reference be added for
consistency, and are there review-specific questions that belong here?

**OQ-28** — `review-process.md` never names the Technical Lead as the responsible review agent.
The connection to the agent roster in `agentic-team.md` is implicit. Should `review-process.md`
explicitly reference the Technical Lead role and entry state (`In Review`) to make the agent
mapping explicit?

---

## Undefined Artifacts and Infrastructure

**OQ-29** — No ADR template or `docs/adr/` directory exists, yet nine ADRs are required before
implementation can begin (`agentic-team.md` ADR Backlog) and ADRs are referenced as mandatory
gates throughout all process documents. What is the ADR format, and where is the template?

**OQ-30** — The GitHub PR template is referenced as required in `agentic-team.md` (Practical
Implementation Recommendations) and `review-process.md` (Adoption Plan), but no
`.github/pull_request_template.md` exists and no document specifies the required sections. What
sections must the PR template include, and who creates it?

**OQ-31** — No document defines the required structure, sections, or format of
`.specify/memory/constitution.md`. Multiple documents require it to be ratified before planning
can proceed, but there is no guidance on what a completed Constitution must contain. What are the
minimum required sections and how should it be structured?

---

## Agent Roster Gaps

**OQ-32** — Review calibration is defined in `review-process.md` (sample merged PRs, compare
findings to outcomes, refine checklists) but has no scheduled trigger in `tracking-process.md`'s
operating cadence. What is the cadence for review calibration, and which agent or human owns it?
