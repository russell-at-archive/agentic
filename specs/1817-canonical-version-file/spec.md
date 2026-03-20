# Feature Specification: Canonical Repository VERSION File

**Feature Branch**: `1817-canonical-version-file`
**Created**: 2026-03-20
**Status**: Draft
**Linear Issue**: INFRA-1817

## User Scenarios & Testing

### User Story 1 - Read a canonical repository version (Priority: P1)

A maintainer or tool can read a single root-level `VERSION` file to determine
the current repository version without inspecting documentation, git tags, or
build metadata.

**Why this priority**: This is the whole value of the request. Without a
canonical file at the repository root, there is no source of truth to consume.

**Independent Test**: From the repository root, read `VERSION` and confirm the
file exists and contains exactly `0.1.0` followed by a single newline.

**Acceptance Scenarios**:

1. **Given** a checkout of the repository root, **When** a maintainer opens
   `VERSION`, **Then** the file exists and contains `0.1.0` with a trailing
   newline.
2. **Given** a script or tool reading plain text from the repository root,
   **When** it reads `VERSION`, **Then** it can consume the version string
   without parsing any other file format.
3. **Given** the change is merged to `main`, **When** consumers inspect the
   repository contents, **Then** the canonical version source is present at the
   root.

### Edge Cases

- If a consumer expects the version file in a subdirectory, that consumer is
  out of scope; the canonical location is the repository root only.
- If future tooling needs machine-readable metadata beyond a single version
  string, that is a separate change and must not expand this scope.
- The file must contain exactly one line with `0.1.0`; extra whitespace, extra
  lines, or comments are not allowed.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST add a plain-text file named `VERSION` at the
  repository root.
- **FR-002**: The `VERSION` file MUST contain exactly `0.1.0` followed by a
  single newline.
- **FR-003**: The change MUST NOT modify any file other than `VERSION` and the
  required planning artifacts for this issue.
- **FR-004**: The repository root `VERSION` file MUST serve as the canonical
  version identifier for future tooling and documentation references.

### Key Entities

- **VERSION file**: A root-level plain-text file containing the repository's
  canonical semantic version string.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `VERSION` exists at the repository root after implementation.
- **SC-002**: `cat VERSION` outputs `0.1.0` with exactly one trailing newline.
- **SC-003**: No non-planning file other than `VERSION` is changed to deliver
  this feature.
