# Task Tracking Process

This document defines the process for tracking the execution of software development tasks within the Archive Agentic workflow. It bridges the gap between high-level planning and the implementation of specific features.

## 1. The Local Source of Truth: `tasks.md`

Every feature implementation begins with a `tasks.md` file located in the feature's specification directory (e.g., `specs/[feature-name]/tasks.md`).

### Format Requirements

Tasks must follow the strict checklist format defined in the `tasks-template.md`:

- `[ ] [TaskID] [P?] [Story?] Description with file path`

### State Management

To provide clear visibility for both humans and AI agents, use the following markers in the `tasks.md` file:

- `[ ]`: **Not Started** — Task is in the backlog.
- `[/]`: **In Progress** — Task is currently being worked on.
- `[x]`: **Completed** — Task is finished and verified.
- `[~]`: **Blocked** — Task cannot proceed (add a comment explaining the blocker).

## 2. Synchronization with GitHub Issues

While `tasks.md` is the local source of truth, GitHub Issues provide team visibility and a platform for discussion.

### Automation

Use the `speckit.taskstoissues` command to convert the `tasks.md` file into a set of GitHub Issues.

- **Issue Titles**: Should include the Task ID and Feature Name (e.g., `[T001] [Auth] Setup project structure`).
- **Issue Description**: Should include a link to the `tasks.md` file and the specific file paths involved.

## 3. The Execution Workflow

Follow this iterative loop for each task:

### Phase 1: Selection

1. Identify: Find the next available task in `tasks.md` by following the dependency order (e.g., Setup → Foundational → User Story P1).
2. Claim: Update the task marker to `[/]` in `tasks.md`.
3. Assign: Assign the corresponding GitHub Issue to the active developer or agent.

### Phase 2: Implementation

1. Branch: Create a focused branch for the task or group of tasks (e.g., `task/T001-setup-structure`).
2. Develop: Execute the implementation according to the plan. Use `speckit.implement` for agent-assisted coding.
3. Verify: Perform manual and automated checks. Each user story must be verified against its "Independent Test" criteria.

### Phase 3: Finalization

1. Commit: Use conventional commit messages referencing the task ID (e.g., `feat: implement user model (T012)`).
2. Close: Update the task marker to `[x]` in `tasks.md` and close the GitHub Issue.
3. Sync: Ensure the branch is merged or a PR is opened before moving to the next independent user story.

## 4. Visibility and Reporting

- **Project Boards**: Use a GitHub Project (Kanban) to visualize the flow of tasks from "To Do" to "Done".
- **Agent Reporting**: When starting a session, the agent should report the current status of the `tasks.md` file and which task is being targeted.
- **Checkpoints**: At the end of each user story phase, validate that the increment is functional and stable before proceeding to the next story.
