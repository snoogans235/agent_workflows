---
name: workflow-pr
description: Prepare, create, or update coding pull requests using verified tickets, small review boundaries, and a consistent five-section description. Use when a project adopts these PR conventions or explicitly requests this skill.
---

# Workflow PR

Use `workflow-commit` for platform-independent ticket verification and concise summary conventions. PR titles follow the format below and do not include commit tags. Read repository instructions and project workflow settings, the approved scope, handoff evidence, and the complete merge-base diff and commits against the intended base.

## Resolve the review boundary

Verify head and base from project policy, issue relationships, recorded branch context, and repository refs together. Git does not permanently record branch origin; an upstream or merge-base alone does not establish the intended base. Never guess or silently retarget a missing parent. The active workflow supplies branching and integration policy; this skill does not impose a branch hierarchy.

## Review size

Aim for approximately 300 changed textual lines as a planning target, not a hard ceiling. Sum numeric additions and deletions from `git diff --numstat BASE...HEAD`, including tests, documentation, schemas, migrations, generated files, and lockfiles. Report binary entries separately.

Above the target, assess whether the PR remains one coherent, readily reviewable change. Split separable behavior into independently understandable PRs. Keep a cohesive change together when splitting would obscure its correctness or leave an incomplete contract; briefly explain the size and rationale in the existing description sections. Do not mechanically split changes to meet a line count, and do not treat being under 300 lines as proof of good scope.

When schema changes, migrations, generated code, lockfiles, or similar repetitive updates drive the size, report their contribution separately alongside the full total. Their volume informs review judgment; it neither disappears from the count nor automatically justifies a larger PR. Consider behavioral breadth, coupling, test evidence, and review effort as well as line count.

Apply the same judgment to integration or release PRs, explaining their scope and linking constituent reviews where applicable. There is no universal numeric ceiling or automatic exemption based on ticket type.

## Readiness and timing

Prepare each Task PR when its scoped implementation, independent verification, and applicable documentation are complete. Required checks must pass at the candidate SHA; refresh affected verification after edits. Explicitly deferred downstream verification/docs remain Story obligations. Do not wait for a dependent Task that requires this Task's integration. Evidence-only Tasks need a handoff, not an empty PR.

For a Story integration PR, verify combined acceptance and required checks after all prerequisite PRs are merged. Distinguish local completion, readiness, publication, merge, and verified integration. PR publication alone does not complete a Task.

## Title and description

Use `<TICKET-ID>: <Summary>`, with no change tag. For an explicitly untracked repository, use `<Summary>` alone. Use the verified issue for this review boundary and retain its canonical identifier, including qualification when needed. Always use these five level-two headings in order:

```markdown
## Summary

The concrete outcome and scope in two or three sentences.

## Background

The problem, relevant context, and why this change is needed.

## What changed

- Significant behavior and decisions, with reasons where useful.
- Compatibility, migration, or limitations when relevant.

## Testing approach

- Strategy and relevant scenarios.
- New or strengthened coverage, existing checks run, actual results, and gaps.

## Future wisdom

One brief original reflection relevant to the work, or a verified attributed quotation.
```

Replace instructional text with evidence. Keep every section proportionate; avoid file-by-file narration and repeated summaries. Link the verified ticket naturally in Summary or Background. Never infer test execution from test files. State when no tests were added and what validation applies. Keep final scope current when revising a PR.

## Publication

Prepare title, body, head, base, diff, and review-line count before publication. Drafting does not authorize publication; a request to create/update a PR does. Reuse existing authorization. Search for an existing PR with this repository/head before creating another; preserve human edits when updating it.

When publication is authorized, push only the intended branch as needed, without force-push. Supply head and base explicitly; use a body file with CLI tools. Verify the returned URL, title, body, head/base, state, published SHA and line count. Attach created PRs to the calling chat when the host supplies an artifact tool. Report partial failures accurately. Publication does not authorize merging, auto-merge, reviewer requests, branch deletion, or ticket closure.
