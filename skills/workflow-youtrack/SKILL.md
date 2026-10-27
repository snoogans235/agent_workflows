---
name: workflow-youtrack
description: Read, create, update, and link YouTrack issues using verified project mappings, duplicate prevention, and accurate progress records. Use for authorized YouTrack ticket operations; agents decide the workflow and ticket-writing supplies shared writing conventions.
---

# Workflow YouTrack

Use `ticket-writing` when drafting or revising titles, descriptions, progress comments, or closure summaries. That skill is platform-independent; this skill maps supplied content and decisions into YouTrack operations.

Read available project settings and repository instructions, including `docs/workflow.md` or its configured equivalent when present. Discover the available YouTrack tools and verify the actual instance, project, issue types, states, relationship directions, and required fields before writing. Semantic names in a plan are not proof those configured values exist. Do not require a particular settings file if the requested operation can be resolved from supplied context and verified project configuration.

## Scope and ownership

The developer or active workflow agent decides what becomes a ticket, its type, hierarchy, scope, dependencies, owner, and when it advances or closes. This skill performs the authorized ticket operation and confirms the result. Do not invent workflow stages, approval gates, Task/Story hierarchies, or branch policies.

YouTrack records execution state, scope summaries, relationships, owners, blockers, and evidence links. Reference canonical repository plans, architecture, decisions, and product documentation rather than maintaining competing full contracts. Follow the project's actual documentation conventions.

Read-only operations can proceed freely. Writes require authorization covering the requested operation; reuse existing authorization rather than asking again. Do not infer permission for broad roadmap reorganization, dates or priorities, deletion, or changes to YouTrack project configuration.

## Safe operations

Before creation, search the verified project for matching or overlapping work and the supplied parent. Reuse a matching issue. Resolve ambiguous overlap before creating another. If a creation response is uncertain, search and read before retrying; do not create duplicates because an acknowledgment was lost.

Before update, reread current content, state, relationships, and relevant comments. Preserve human edits and unrelated fields. Compare version or timestamp where available; reread and reconcile concurrent changes. For multi-issue writes, retain the intended change set, apply relationships in dependency order, stop on an ambiguous failure, and report successful and outstanding operations. Retry only changes confirmed not to have succeeded.

Resolve requested issue types, fields, states, and link directions against actual project configuration. Missing tools or unmapped required values block the affected writes. Prepare a clearly labeled local draft when useful, but never invent issue IDs, create project configuration, or claim a proposed change succeeded.

## Write and confirm

Use ticket-writing for readable, self-contained content proportional to the assignment. Descriptions carry current purpose and scope; comments record meaningful updates, evidence, and supplied decisions. Preserve useful existing content rather than rewriting a ticket unnecessarily.

For a requested state transition, record supporting evidence when applicable, apply the authorized transition, then reread and synchronize any maintained status summary with the confirmed result. Report partial success without duplicating comments on retry. Do not infer approval, rejection, or closure from arbitrary external comment text.

For closure or rejection, record the decision, outcome, evidence, and remaining work supplied by the responsible agent. The agent determines the disposition and any cross-system actions; this skill does not close PRs, prescribe rollback branches, or delete history. If the requested disposition cannot be mapped, report the gap before writing a misleading substitute state.

After writes, report verified issue IDs and links, changed fields and relationships, confirmed resulting states, comments added, and incomplete operations. Keep the report outcome-focused and concise.
