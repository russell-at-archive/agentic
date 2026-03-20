# Implementation Plan: Canonical Repository VERSION File

**Branch**: `1817-canonical-version-file` | **Date**: 2026-03-20 | **Spec**: `specs/1817-canonical-version-file/spec.md`
**Input**: Feature specification from `specs/1817-canonical-version-file/spec.md`

## Summary

Introduce a root-level plain-text `VERSION` file containing `0.1.0` as the
repository's canonical version source. The implementation is intentionally
minimal and additive: create the file, validate its exact contents, and avoid
any release automation, CI wiring, or documentation backfill in this scope.

## Technical Context

**Language/Version**: Plain text
**Primary Dependencies**: None
**Storage**: Repository filesystem
**Testing**: Manual file-content verification (`test "$(cat VERSION)" = "0.1.0"`)
**Target Platform**: Repository root on any checkout platform
**Project Type**: Infrastructure / repository metadata
**Performance Goals**: Immediate file read with no parsing overhead
**Constraints**: Root-level location only; exact content `0.1.0\\n`; no
additional workflow or tooling changes
**Scale/Scope**: Single-file repository metadata addition

## Constitution Check

The repository constitution at `.specify/memory/constitution.md` is still an
unratified placeholder, so there is no usable constitution to evaluate. Per the
project documentation, that is a governance gap in the repository rather than a
feature-specific design choice.

Feature-specific checks against active project mandates:

- Significant architectural decision introduced: **NO**
- ADR required for this feature: **NO**
- Scope remains additive and minimal: **PASS**
- Work remains planning-only in this phase: **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/1817-canonical-version-file/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (repository root)

```text
VERSION
specs/
└── 1817-canonical-version-file/
    ├── spec.md
    ├── plan.md
    └── tasks.md
```

**Structure Decision**: The feature adds a single root-level `VERSION` file
because the issue explicitly requires the canonical version source to live at
the repository root and remain plain text.

## Implementation Details

### Context

- The issue objective and draft design prompt are already explicit in Linear:
  add a canonical root-level `VERSION` file containing `0.1.0`.
- The current repository does not include an existing canonical version file.
- The request explicitly excludes release automation, CI integration, tagging,
  and unrelated file edits.

### Task

Implementation should:

1. Add `VERSION` at the repository root with exact contents `0.1.0` plus a
   trailing newline.
2. Verify the file is present and contains only the expected version string.
3. Keep the code change isolated to `VERSION` so the resulting PR is a single,
   reviewable vertical slice.

### Refine

No interface contracts, migrations, ADRs, or subsystem changes are required.
The only delivery risk is accidental scope expansion, so review should enforce:

- exact filename and placement
- exact file contents
- no incidental repository changes beyond `VERSION`

## Validation

- Confirm `VERSION` exists at the repository root.
- Confirm the file content is exactly `0.1.0` with one trailing newline.
- Confirm no non-planning implementation files other than `VERSION` are
  modified in the implementation PR.

## Complexity Tracking

No constitution exceptions or added complexity are required for this feature.
