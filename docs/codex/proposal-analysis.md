# Team Proposal Analysis

## Objective

Compare the three existing team proposals and identify the strongest elements to carry into a single merged operating model.

Reviewed documents:

- [docs/codex/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/team-proposal.md)
- [docs/claude/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/claude/team-proposal.md)
- [docs/gemini/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/gemini/team-proposal.md)

## Comparison Summary

## Strengths in `docs/claude/team-proposal.md`

- Best end-to-end operational detail for each role.
- Strongest definition of Director dispatch behavior and state-driven routing.
- Best treatment of planning artifact flow with Speckit commands and outputs.
- Best alignment with repository process docs (`planning`, `implementation`, `review`, `tracking`).
- Clear handling of blocked behavior and escalation.

Trade-off:

- Long and process-heavy. Some sections can be normalized into concise policy statements.

## Strengths in `docs/codex/team-proposal.md`

- Strong gap taxonomy that isolates missing controls.
- Strong role contracts using input, precondition, output, and exit criteria.
- Strong concurrency and locking model (ticket lock and branch namespace lock).
- Strong quality gate framing and measurable observability metrics.
- Strong ADR backlog framing for implementation-readiness.

Trade-off:

- Less concrete on some runtime behaviors (for example execution logs and dispatch mechanics).

## Strengths in `docs/gemini/team-proposal.md`

- Clear narrative around spec-driven development philosophy.
- Strong recommendation for an execution log protocol in Linear for resumability.
- Useful operational recommendations: canonical validation command and PR template structure.
- Good emphasis on traceability requirements and multi-tier review semantics.

Trade-off:

- Less explicit about failure policies, locking, and ownership boundaries.

## Conflict and Divergence Analysis

## Divergence 1: Dispatch and orchestration model depth

- `claude` defines a precise dispatch table and orchestration model relationship.
- `codex` defines strict contracts and governance controls.
- `gemini` is lighter on orchestration specifics.

Resolution:

- Use `claude` dispatch model and integrate `codex` contract gates.

## Divergence 2: How prescriptive implementation should be

- `claude` names concrete command flows and role behavior.
- `codex` focuses on policy and outcomes.
- `gemini` adds practical conventions (execution log, template needs).

Resolution:

- Keep explicit behavior but move command-level examples to implementation appendix later.

## Divergence 3: Quality and auditability mechanisms

- `codex` emphasizes metrics and SLO-like signals.
- `gemini` emphasizes execution log audit trail.
- `claude` emphasizes stage-specific evidence.

Resolution:

- Require all three: evidence artifacts, execution log, and operational metrics.

## Divergence 4: ADR and architecture governance treatment

- `claude` and `codex` both flag major ADR needs.
- `gemini` is less explicit on ADR backlog and decision boundaries.

Resolution:

- Adopt `codex` ADR backlog structure plus `claude` role-level ADR checks.

## Gaps Remaining Across All Three

- Initial intake ownership (human triage vs. future Triage agent) remains unresolved.
- Authentication and secrets lifecycle for all external tools remains unresolved.
- Exact Director runtime mode (polling, webhook, hybrid) remains unresolved.
- Maximum Graphite stack depth policy remains unresolved.
- Formal incident severity and on-call ownership model is not yet defined.

## Best-Idea Retention Matrix

| Capability | Best Source | Merge Decision |
| --- | --- | --- |
| Canonical state model and dispatch mapping | `claude` | Adopt fully, normalize wording |
| Role contracts and transition gates | `codex` | Adopt fully |
| Execution log resumability protocol | `gemini` | Adopt fully |
| Concurrency and lock semantics | `codex` | Adopt fully |
| Research invocation/output format | `claude` | Adopt fully |
| Quality evidence + review tiers | `claude` + `gemini` | Combine |
| Metrics and reporting cadence | `codex` | Adopt fully |
| Implementation readiness recommendations | `gemini` | Adopt fully |
| ADR backlog and architecture control points | `codex` + `claude` | Combine |

## Conclusion

The strongest merged model uses `claude` as the operational backbone, `codex` as the governance and control layer, and `gemini` for execution-log and implementation hygiene practices. This combined approach yields a coherent system that is both executable and enforceable.
