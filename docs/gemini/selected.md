# Selection: Canonical Feature Draft Agent Proposal

**Selected Document**: `docs/claude/merged.md`

## Defense of Selection

After a deep analysis of the three competing `merged.md` proposals, the version in **`docs/claude/merged.md`** is selected as the strongest, most coherent, and most operationally rigorous design. Its selection is defended based on the following architectural and technical merits:

### 1. Superior Traceability and Contextual Grounding
Unlike the other versions, this proposal explicitly maps its changes to the existing project documentation (`docs/agentic-team.md`, `docs/planning-process.md`, `docs/tracking-process.md`) and specifically resolves **OQ-06** from `docs/open-questions.md`. It treats the new agent as a deliberate evolution of the current system rather than an isolated feature.

### 2. Architectural Integrity and "System Thinking"
The proposal addresses the "structural exception" of the Drafter—being human-invoked rather than Director-dispatched—head-on. It successfully defends the choice of a **Phase 0.5 (Pre-Lifecycle)** role over adding complexity to the Linear state machine, maintaining a cleaner boundary between "ideation" and "tracked execution."

### 3. Operational Precision: The Nine-Question Rule
It defines a specific **Conversation Protocol** with a hard cap of nine questions across three passes (Context, Task, Refine). This prevents "interrogation fatigue" and ensures the agent remains a high-speed intake tool rather than an aimless conversationalist.

### 4. Mandatory Verification Gate
The proposal introduces a critical **Verification Gate** where the Drafter must present the synthesized CTR block to the stakeholder for explicit confirmation before writing to Linear. This is a vital quality-control measure that prevents the autonomous creation of hallucinated or noisy tickets.

### 5. Differentiated CTR Framework
A key strength is the distinction between the **Architect's technical CTR** and the **Drafter's product-focused CTR**. By framing the Drafter's output as a "Design Prompt" rather than a technical plan, it preserves the single-responsibility principle and prevents the Drafter from drifting into implementation details.

### 6. Comprehensive Risk Management
The document includes a thorough **Risks and Mitigations** section and an **Alternatives Considered** analysis. It anticipates failure modes—such as the Drafter accepting vague answers or overlapping with the Architect—and provides actionable mitigations through tool-access restrictions and mandatory open-question documentation.

### 7. Implementation-Ready Specification
The inclusion of a detailed **Agent Specification** (including model recommendations, tool access tables, and specific Markdown templates) makes this document a ready-to-execute blueprint. It outlines the exact follow-on changes required for `AGENTS.md` and the lifecycle phases, providing a complete "blast radius" for the adoption.

## Conclusion
The Claude version represents a masterclass in **RFC-level documentation**. It provides the technical rationale, operational guardrails, and implementation details necessary for a system-wide architectural shift, making it the clear choice for the canonical design.
