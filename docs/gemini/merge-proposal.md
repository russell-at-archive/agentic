# Unified Review Process: The Archive Agentic Standard

## Purpose

This document synthesizes the best aspects of the Claude, Codex, and Gemini review proposals into a single, cohesive, and non-negotiable workflow. It combines a rigorous 6-step execution loop with the "Torvalds Standard" for architectural excellence.

Review is the final gate. Its goal is not to validate effort, but to ensure that every change is technically superior, maintainable for a decade, and perfectly aligned with the project's soul.

## 1. Philosophy: Justified Confidence

- **Review as an Interrogation:** We adopt a skeptical stance. The code is guilty of being technically inferior until proven otherwise through evidence and clarity.
- **Author's Burden:** The author is 100% responsible for the clarity and reviewability of the submission. A missing explanation is a defect.
- **Maintainability over Velocity:** We will not merge "good enough" today if it creates technical debt for tomorrow.
- **Traceability:** Every line of code must be traceable to an approved `spec.md`, `plan.md`, and `task.md`.

## 2. The 6-Step Review Workflow

Every formal review must follow this exact sequence:

### Step 1: Intake and Pre-Validation

Before reading the diff, confirm:

- [ ] PR links to the governing `spec.md`, `plan.md`, and `tasks.md`.
- [ ] Linked GitHub Issue is in `status:in-review`.
- [ ] CI (Build, Lint, Type-check) and full test suite pass with zero warnings.
- [ ] The PR is "review-sized" (one task per PR).
- [ ] All architectural changes have a corresponding ADR.

### Step 2: Intent Reconstruction

The reviewer must read the planning artifacts first. They should be able to state the intended behavior and constraints in plain language before judging the code.

### Step 3: The "Torvalds" Diff Review

This is the technical heart of the process. Review the patch through these lenses:

- **Correctness:** Does it satisfy the acceptance criteria?
- **The Torvalds Checklist:**
  1. Is this the simplest way to solve the problem? (Avoid over-engineering).
  2. Is the abstraction clean, or does it leak logic across boundaries?
  3. Are variable, function, and file names descriptive and idiomatic?
  4. If this code breaks at 3 AM, can an engineer diagnose it quickly?
  5. Is the change "technically superior" or just a functional patch?
- **Failure Modes:** Are edge cases and failure paths handled, or just the "happy path"?

### Step 4: Validation Review

Verify that the evidence provided matches the risk of the change.

- New behavior requires tests.
- Bug fixes require regression tests.
- Refactors must maintain or improve existing coverage.

### Step 5: Verdict

Every review must end with an explicit verdict:

- `approve`: Sufficient confidence for merge; zero blocking defects.
- `revise`: Technically sound direction, but specific defects must be fixed.
- `reject`: Fundamentally unreviewable, out of scope, or architecturally inconsistent.

### Step 6: Re-Review

Re-checks must verify that all blocking findings are resolved and that no new regressions were introduced by the fixes.

## 3. The Comment Taxonomy

To ensure machine-readability and clear prioritization, all review comments must use these prefixes:

| Prefix | Meaning |
| :--- | :--- |
| `blocking:` | Must be resolved before approval. Non-negotiable quality or correctness issue. |
| `question:` | Must be answered before confidence is sufficient. |
| `suggestion:` | Optional improvement. Not required for merge. |
| `note:` | Context or observation. No action required. |

## 4. Role Definitions

### Author

Responsible for supplying validation evidence, maintaining scope discipline, and responding to every material finding.

### Reviewer

Responsible for independently evaluating the diff, identifying risks, and blocking when confidence is insufficient.

### Reviewing Agent

Acts as a strict, findings-first reviewer. Agents must cite concrete file and line references and avoid conversational filler or vague praise.

## 5. Risk Tiers and Service Levels

| Risk Tier | Requirements | Target Turnaround |
| :--- | :--- | :--- |
| **Low** | Basic artifact traceability; fast-path review. | 1 Business Day |
| **Standard** | Full 6-step review; complete validation evidence. | 1 Business Day |
| **High** | Two reviewers (one domain owner); linked ADR; failure mode review. | 2 Business Days |

## 6. Adoption and Metrics

We track the health of this process through:

- **Rework Rate:** Percentage of PRs requiring multiple revision cycles.
- **Escaped Defect Rate:** Bugs found in production that should have been caught in review.
- **Scope Rejection Rate:** PRs rejected for implementing more than the approved task.

## Next Steps

1. **Ratify:** Merge this proposal as the project standard via an ADR.
2. **Template:** Incorporate the "Torvalds Checklist" and Comment Taxonomy into the repository PR template.
3. **Calibrate:** Run a recurring review calibration every two weeks to identify blind spots in the process.
