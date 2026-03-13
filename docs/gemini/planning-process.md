# Spec-Driven Development Planning Process

Spec-Driven Development (SDD) — often closely related to README-Driven Development or Design Document-Driven Development — is a methodology where the specification or plan is written *before* any code. The core philosophy is that clarifying the "what" and "how" in plain text is much cheaper, faster, and less error-prone than refactoring code later.

This repository structure, particularly the `.specify` directory containing templates and the `speckit.*` commands, is highly optimized for a structured, agent-assisted spec-driven workflow.

## 1. The Discovery & Clarification Phase

Before writing a formal specification, it's essential to ensure the problem is fully understood.

* **Goal:** Define the core problem, target audience, and business value.
* **Process:** Ask critical questions. Challenge initial assumptions. Explicitly define what is *out of scope*.
* **Tooling Alignment:** This phase aligns with the `speckit.clarify` and `speckit.analyze` steps in your agent workflows.

## 2. The Product/Feature Specification (The "What")

This is the human-readable document that describes what the feature will accomplish from a user or system perspective.

* **Goal:** Align all stakeholders (engineers, product managers, designers) on the expected outcome before technical decisions are made.
* **Key Components:**
  * **Background & Motivation:** Why are we building this?
  * **User Stories / Use Cases:** How will users interact with it?
  * **Acceptance Criteria:** Exactly how do we know it is finished and working correctly?
  * **Scope Boundaries:** What are the strict limits of this feature?
* **Tooling Alignment:** This corresponds to the `spec-template.md` and the `speckit.specify` step.

## 3. The Technical Plan / Architecture (The "How")

Once the "what" is established, engineering defines how to build it within the existing system constraints.

* **Goal:** Identify necessary architectural changes, API contracts, data models, and potential risks before writing code.
* **Key Components:**
  * **System Context:** How does this new feature integrate with the current architecture?
  * **Data Models & API Contracts:** Exact definitions of new database tables, API endpoints, or software interfaces.
  * **Implementation Strategy:** A step-by-step technical approach.
  * **Security & Performance:** Considerations and mitigation strategies.
* **Tooling Alignment:** This corresponds to the `plan-template.md` and the `speckit.plan` step.

## 4. Task Decomposition (The Execution Plan)

A technical plan is typically too large to execute cleanly in one attempt. It must be broken down into manageable pieces.

* **Goal:** Create small, atomic, and testable units of work.
* **Process:** Generate a list of specific tasks, ideally ordered by their technical dependencies. Each task should be scoped small enough to represent a single Pull Request or a focused work session.
* **Tooling Alignment:** This corresponds to the `tasks-template.md`, `checklist-template.md`, and the `speckit.tasks` / `speckit.taskstoissues` steps.

## 5. Implementation & Verification

Only after the previous steps are complete does the actual coding begin.

* **Goal:** Execute the tasks exactly as specified in the prior phases.
* **Process:** Pick up a single task, implement the code, write automated tests proving it meets the acceptance criteria defined in Step 2, and verify the implementation matches the technical design in Step 3.
* **Tooling Alignment:** This aligns with the `speckit.implement` step.

---

## Synergy with AI Agents

AI agents thrive on clear, unambiguous context. A vague request like "build a login system" forces an AI to guess the architecture, tools, and UX patterns.

Conversely, when an AI is provided with a well-defined `spec.md` and `plan.md`, it can consistently generate highly accurate `tasks.md` documents. Furthermore, it can flawlessly execute those isolated tasks one by one, drastically reducing hallucinations and implementation errors while dramatically increasing delivery speed.
