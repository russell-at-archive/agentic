# Software Review Process: The Archive Agentic Standard

## Purpose

This document defines the unified review process for Archive Agentic. It synthesizes the deliberate, skeptical, and technically demanding standards of the project's delivery system into a single, cohesive workflow.

Review is the final gate. Its goal is not to validate effort, but to ensure that every change is technically superior, maintainable for a decade, and perfectly aligned with the project's architectural vision. We do not seek polite approval; we seek **justified confidence**.

## 1. Review Philosophy: The Torvalds Standard

- **Review as an Interrogation:** We adopt a skeptical stance. Code is considered technically inferior until proven otherwise through evidence, clarity, and architectural integrity.
- **Author's Burden:** The author is 100% responsible for the clarity and reviewability of the submission. A missing explanation is a defect.
- **Correctness Over Speed:** We value reliability over theoretical elegance and long-term maintainability over merge velocity.
- **Traceability:** Every substantive claim in a pull request must be traceable to code, tests, and approved planning artifacts (`spec.md`, `plan.md`, `tasks.md`).

## 2. Review Goals

Every review must answer these questions:

1. Is the change correct relative to the approved planning artifacts?
2. Is the behavior safe in normal, edge, and failure conditions?
3. Is the design the simplest possible way to solve the problem?
4. Are tests sufficient to catch regressions and prove the intended behavior?
5. Is the code understandable enough that a future engineer can modify it safely?
6. Does the change maintain or improve the project's architectural integrity?

## 3. The 6-Step Review Workflow

### Step 1: Intake Check (Pre-Validation)

Before reading the diff in detail, the reviewer confirms:

- [ ] PR links to the governing `spec.md`, `plan.md`, and `tasks.md`.
- [ ] Linked GitHub Issue is in `status:in-review`.
- [ ] CI (Build, Lint, Type-check) and full test suite pass with zero warnings.
- [ ] The PR is "review-sized" (one task per PR).
- [ ] Any architectural change has a corresponding ADR.

If any input is missing, the reviewer stops and returns the PR for correction.

### Step 2: Intent Reconstruction

The reviewer reads the planning artifacts first to understand the intended behavior and constraints. They should be able to state the goal in plain language before judging the code.

### Step 3: The Technical Review (The Torvalds Core)

Review the patch with emphasis on correctness, safety, and the **Torvalds Checklist**:

1. **Simplicity:** Is this the simplest way to solve the problem? (Avoid over-engineering).
2. **Abstractions:** Is the abstraction clean, or does it leak logic across boundaries?
3. **Naming:** Are variable, function, and file names descriptive and idiomatic?
4. **Observability:** If this code breaks at 3 AM, can an engineer diagnose it quickly?
5. **Side Effects:** Does this change have hidden impacts on other subsystems?

### Step 4: Validation Review

Check that the evidence is proportionate to the risk:

- New behavior must have automated tests.
- Bug fixes require regression tests.
- Refactors must preserve or improve coverage.
- Manual validation (logs, screenshots) is documented when automation is not feasible.

### Step 5: Verdict

The reviewer leaves one of three outcomes:

- `approve`: Sufficient confidence for merge; zero blocking findings.
- `revise`: Technically sound direction, but specific defects must be fixed.
- `reject`: Fundamentally unreviewable, out of scope, or architecturally inconsistent.

### Step 6: Re-Review

After the author updates the PR, the reviewer re-checks blocking findings and verifies that no new regressions were introduced by the fixes.

## 4. The Comment Taxonomy

To ensure machine-readability and clear prioritization, all review comments must use these prefixes:

| Prefix | Meaning |
| :--- | :--- |
| `blocking:` | Must be resolved before approval. Non-negotiable quality or correctness issue. |
| `question:` | Must be answered before confidence is sufficient. |
| `suggestion:` | Optional improvement. Not required for merge. |
| `note:` | Context or observation. No action required. |

### Findings Standard

Every `blocking:` finding must contain:

- A clear statement of the problem.
- Why it matters (the technical risk).
- The affected file and line reference.
- The expected correction or the question to be resolved.

## 5. Agent-Specific Review Rules

When agents are involved in the review process:

1. **Peer Review:** Agents should review each other's work before a human is involved.
2. **Execution Logs:** Reviewers must check the agent's `## Execution Log` in the GitHub Issue to verify the process (e.g., failing test first).
3. **Findings First:** Agent review output must lead with findings, not summaries.

## 6. Risk Tiers and Service Levels

| Risk Tier | Requirements | Target Turnaround |
| :--- | :--- | :--- |
| **Low** | Basic artifact traceability; fast-path review. | 1 Business Day |
| **Standard** | Full 6-step review; complete validation evidence. | 1 Business Day |
| **High** | Two reviewers; linked ADR; failure mode review. | 2 Business Days |

## 7. Escalation Rules

Escalate to the **Tech Lead** or **Architecture Owner** when:

- The PR conflicts with approved planning artifacts.
- The author and reviewer disagree on intended behavior or architectural "correctness."
- A significant architectural choice is made without an ADR.

## 8. Definition of Done for Review

Review is complete only when:

- All blocking findings are resolved.
- The reviewer can explain why the change is safe and technically superior.
- Planning traceability is intact and all acceptance criteria are verified.
- The final verdict is explicit and justified.
