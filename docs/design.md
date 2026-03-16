# Notes

Design a system for autonomous agentic software engineering.
Dictate workflows, processes, and tools for agents to use to perform their job functions.

## Agent Team

1. Director (foreman)
Polls Linear app
invokes agents to perform tasks

1. Architect (planning)
uses github speckit for feature planning
creates relevant ADR documents
structures plan tasks to be approriatly sized for stacked graphite pull requests
publishes plan documents pull request for plan review

1. Coordinator (scheduling)
invoked with linear ticket id
ticket state must be in ready for scheduling status
creates linear tickets from accepted plan

1. Engineer (implementation)
invoked with linear ticket id
ticket state must be in ready for implementation status
creates worktree
marks linear ticket as in progress
submits each task as a graphite stacked pr
publish stacked pr for review
marks linear ticket as in review

1. Technical Lead (review)
invoked with linear ticket id
ticket state must be in ready for review status
perform review of pull request

1. Explorer (research)
perform research operations
produce well formatted reports with source citations

## Linear Ticket States

Draft
Planning
Plan Review
Backlog
Selected
Blocked
In Progress
In Review
Done

## Tools

1. AWS (cloud provider)
1. Github Speckit (planning)
1. Linear App (task tracking)
1. Github (scm)
1. Graphite (review)
