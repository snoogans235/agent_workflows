---
name: workflow-commit
description: Prepare or create ticket-linked coding commits with consistent change tags and concise changelog summaries. Use when a project adopts these commit conventions or explicitly requests this skill.
---

# Workflow Commit

Read repository instructions, the relevant diff, and the project's workflow settings. Use the most specific ticket covering the actual change. Resolve the project's configured issue tracker and use its available integration, API, or CLI to read the actual ticket and verify its canonical identifier and scope. Never infer validity from a branch name, an old commit, or an identifier's shape. If the tracker is ambiguous, resolve it from project context or ask rather than guessing.

Ticket verification is platform-independent. Follow any applicable project-specific tracker instructions without requiring a particular provider or tracker skill. Preserve the tracker's canonical identifier, including repository/project qualification when needed to make it unambiguous.

A repository explicitly declared untracked may omit the ticket prefix. Missing tracker access in a tracked repository is a blocker, not an untracked exception. Ask only if the intended ticket cannot be resolved from current context.

## Format

```text
<TICKET-ID> <TAG>: <Summary>

- Optional concise detail
- Another detail only when useful
```

Use exactly one verified ID and uppercase tag. Begin the summary with a capitalized changelog verb (Adds, Fixes, Updates, Removes), omit a trailing period, and aim for 72 subject characters without truncating the ID or meaning. Omit the body when unnecessary; otherwise use one blank line and at most three short bullets. Put breaking changes or required migrations first. State only supported outcomes and verification.

| Tag | Primary purpose |
| --- | --- |
| FEATURE | Adds or extends functionality |
| BUGFIX | Corrects behavior |
| REFACTOR | Restructures without changing behavior |
| PERF | Improves performance |
| DOCS | Documentation |
| TEST | Tests |
| CHORE | Tooling, dependencies, maintenance, CI |
| REVERT | Reverses an earlier change |

Feature-related tests and docs use FEATURE when part of that change. Split unrelated work rather than hiding it under a broad ticket or summary.

## Commit boundary

A message request produces a message. A commit request authorizes the local commit. Inspect required verification and the final staged diff; stage only intended files and preserve unrelated staging. Use a message file for multiline text. Verify the resulting hash and subject and report remaining changes. Do not amend, push, publish a PR, or close a ticket without authorization covering that action. Existing authorization remains valid; do not ask for it again.
