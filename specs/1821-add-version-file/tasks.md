# Tasks: Add VERSION File

**Input**: Design documents from `specs/1821-add-version-file/`
**Prerequisites**: plan.md (required), spec.md (required)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)

## Phase 1: User Story 1 - Canonical Repository Version (Priority: P1)

**Goal**: Add the repository-root `VERSION` file as the canonical version
identifier.

**Independent Test**: Read `VERSION` from the repository root and confirm it
contains exactly `0.1.0` followed by one newline, with no unrelated product
file changes in the diff.

### Implementation for User Story 1

- [ ] T001 [US1] Create `VERSION` at the repository root with exact content
  `0.1.0` followed by a single newline, then verify no unrelated product files
  changed beyond that addition

**Checkpoint**: The repository exposes a single canonical version file at the
root with the required content.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies; this is the full MVP and complete feature scope.

### Parallel Opportunities

- None. The issue scope is intentionally a single-file, single-task change.

### Recommended Execution Order

1. T001

## Notes

- This feature intentionally fits in one Graphite stacked PR.
- Validation for T001 should confirm exact file contents and that no unrelated
  product files changed.
