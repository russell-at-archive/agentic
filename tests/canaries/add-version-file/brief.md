# Canary Brief: Add VERSION File

## Context

This repository has no canonical version identifier. Other tooling and
documentation may eventually need to reference the project version, and there
is currently no agreed-upon source of truth for it.

## Task

Add a plain-text `VERSION` file to the repository root containing the string
`0.1.0`.

## Must-Haves

- `VERSION` file exists at the repository root
- File contains exactly `0.1.0` followed by a single newline
- File is committed and present on `main`

## Non-Goals

- No semver automation or release tooling
- No CI integration or version tagging
- No changes to any other file

## Constraints

- File must live at the repo root, not in a subdirectory
- No build system changes required

## Risks

- None identified for this scope

## Open Questions

- None

## Acceptance Signal

`VERSION` file is present on `main` and its contents equal `0.1.0`.
