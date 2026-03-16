# Proposal Analysis: Comparing the Agent Team Proposals

We have three distinct proposals for the Agent Team structure and workflows, located in `docs/gemini/team-proposal.md`, `docs/claude/team-proposal.md`, and `docs/codex/team-proposal.md`. Each addresses the gaps in the original `docs/design.md` but takes a slightly different angle based on the underlying model's focus.

## 1. Gemini Proposal (`docs/gemini/team-proposal.md`)
**Focus**: Narrative clarity, foundational principles, and resumability.
**Key Strengths**:
- Anchors the team strictly to the **Spec-Driven Development** philosophy.
- Introduces the **"Execution Log" Protocol** as a mandatory requirement for agents, ensuring resumability, transparency, and safe handoffs between human and agent.
- Clearly maps the explicit Quality Gates (T-1 to T-8, I-1 to I-9) to the agent responsibilities.

## 2. Claude Proposal (`docs/claude/team-proposal.md`)
**Focus**: Operational rigor, interface contracts, and team scalability.
**Key Strengths**:
- Introduces **Strict Role Contracts** (Inputs, Preconditions, Outputs, Failure Policy) for every agent, treating them like microservices.
- Adds **Cross-Cutting Control Agents** (Compliance Gate, Metrics Reporter) to enforce rules outside the main delivery loop.
- Defines a robust **Concurrency and Locking Model** (e.g., ticket locks, PR namespace locks) to prevent agent collisions.
- Explicitly addresses **Incident Recovery**, **Observability**, and **SLOs/Metrics**.
- Provides a practical **Phased Rollout Plan**.

## 3. Codex Proposal (`docs/codex/team-proposal.md`)
**Focus**: System architecture, agent invocation modeling, and decision tracking.
**Key Strengths**:
- Deeply analyzes the **Agent Invocation Model**, contrasting the Director's system-level orchestration with the underlying `codex` multi-agent pipeline (the execution substrate).
- Explicitly models **LLM Reasoning Effort** (Low/Medium/High) per agent, which is critical for cost and latency optimization.
- Provides a comprehensive **Tool Assignment Matrix**.
- Highlights specific edge cases (e.g., Engineer worktree lifecycle, Technical Lead's high-risk escalation).
- Generates a very specific, prioritized **ADR Backlog** for unresolved system decisions.

## Conclusion
The three proposals are highly complementary. Gemini provides the narrative glue and handoff human-readability (Execution Log). Claude hardens the operational boundaries (Contracts, Concurrency, Metrics). Codex clarifies the technical execution architecture (Pipelines, LLM effort, Tooling matrices). Merging them will yield a highly rigorous, production-ready specification.