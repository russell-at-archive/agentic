# Planning Process Analysis: Claude, Codex, and Gemini

This document analyzes and compares the Spec-Driven Development (SDD) planning processes proposed by the Claude, Codex, and Gemini agents within this repository.

## Executive Summary

While all three agents align on the foundational principles of SDD—prioritizing planning over implementation—each brings a distinct perspective to the lifecycle:

- **Claude** (The Operator): Focuses on the **mechanics** of the Speckit toolchain.
- **Codex** (The Architect): Focuses on **governance**, classification, and architectural integrity.
- **Gemini** (The Strategist): Focuses on the **discovery phase** and AI/Human collaboration.

## Comparative Breakdown

| Feature | Claude | Codex | Gemini |
| :--- | :--- | :--- | :--- |
| **Primary Lens** | Toolchain & Lifecycle | Governance & Quality Gates | Strategy & Synergy |
| **Core Workflow** | Spec → Plan → Tasks → Implement | Intake → Spec → Plan → Tasks | Discovery → Spec → Plan → Tasks |
| **Success Metric** | Passing automated quality gates | Tech Lead approval & ADR compliance | Stakeholder alignment & AI accuracy |
| **Unique Asset** | Phase 0 Research Step | Change Classification System | Explicit Discovery Phase |

## Key Methodology Perspectives

### 1. Claude: Procedural Rigor

Claude's document acts as an operational manual. It explicitly maps the `speckit.*` commands to specific project milestones. Its strongest contribution is the **Phase 0 (Research)** step in the planning phase, which mandates resolving technical unknowns before finalizing a design.

### 2. Codex: Governance and Guardrails

Codex introduces a formal **Classification System** (Feature, Bug, Refactor, etc.) that scales the planning depth based on risk and scope. It emphasizes "hard gates," requiring Tech Lead approval at every stage and mandating a test matrix for all plans.

### 3. Gemini: Discovery and Synergy

Gemini highlights the "why" behind SDD, particularly for AI-assisted workflows. It emphasizes a **Discovery & Clarification** phase *before* formalizing a spec, ensuring that the problem is fully understood and scope boundaries are explicitly defined to reduce agent "hallucinations."

## Shared Foundational Principles

Across all three documents, several non-negotiable standards emerge:

1. Vertical Slices: Plan and implement in thin, independently shippable slices.
2. Explicit Gates: No implementation begins until the `spec.md`, `plan.md`, and `tasks.md` are complete and validated.
3. The Constitution: The project constitution (in `.specify/memory/constitution.md`) is the ultimate source of engineering truth.
4. Traceability: Every Pull Request must trace back to an approved task, plan, and specification.

## Synthesis & Recommendations

To create the most robust version of the SDD process for this project, the following elements should be combined:

- **From Codex:** Adopt the 5-tier classification system to determine the required artifact depth.
- **From Claude:** Integrate the "Phase 0 Research" requirement into the `speckit.plan` command workflow.
- **From Gemini:** Enforce the "Discovery & Clarification" phase as a mandatory precursor to `speckit.specify`.

**Next Steps:**

- Ratify the project constitution using these combined principles.
- Update the `speckit.*` command prompts to reflect these unified quality gates.
