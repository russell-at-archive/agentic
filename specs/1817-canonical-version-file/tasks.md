# Tasks: Canonical Repository VERSION File

**Input**: Design documents from `specs/1817-canonical-version-file/`
**Prerequisites**: plan.md (required), spec.md (required)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)

## Phase 1: User Story 1 - Read a canonical repository version (Priority: P1)

**Goal**: Add a single canonical root-level version file that humans and tools
can read directly.

**Independent Test**: Read `VERSION` from the repository root and confirm it
contains exactly `0.1.0` followed by one newline.

### Implementation for User Story 1

- [ ] T001 [US1] Add root-level `VERSION` with exact contents `0.1.0` plus a
  trailing newline.
- [ ] T002 [US1] Verify `VERSION` content from the repository root using a
  direct file-content check and confirm no extra implementation files were
  changed. (Depends on T001)

**Checkpoint**: The repository has one canonical version source at `VERSION`
with the required exact content.

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1**: No prerequisites beyond the approved planning artifacts.

### Recommended Execution Order

1. T001 add the file.
2. T002 verify exact content and isolated scope.

## Notes

- Each task is sized to fit a single Graphite stacked PR.
- No ADR is required because this feature does not introduce a significant
  architectural decision.
- Do not expand scope into release automation, CI, tagging, or documentation
  updates.
