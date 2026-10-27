---
name: ticket-writing
description: Draft or revise clear software tickets, progress updates, and closure summaries from supplied intent and evidence. Use across issue trackers; workflow agents decide scope, ticket hierarchy, readiness, and state changes.
---

# Ticket Writing

Write for a teammate who has not followed the conversation. Use plain, direct, professional language, concrete behavior, and enough context to explain why the work matters. Be technically precise without requiring the reader to decode internal shorthand.

This skill owns writing conventions. The developer or workflow agent supplies the purpose, scope, acceptance requirements, dependencies, work-unit type, and intended operation. The tracker integration skill maps the content to platform fields and performs authorized writes. Drafting a ticket does not authorize publication or a state change.

## Tone and language

- Lead with the intended outcome and why it matters. Prefer familiar words and active verbs.
- Name the actual behavior, component, or dependency. Avoid inflated phrases such as "operationalize the orchestration boundary" and vague goals such as "ensure robustness."
- Keep necessary technical terms, exact identifiers, and error messages when they help the assignee act or verify behavior. Explain unfamiliar terminology briefly on first use; do not replace precise meaning with a vague simplification.
- Make the assignment understandable on its own. Links provide supporting detail; they must not be the only explanation of the purpose, scope, or acceptance conditions.
- Present requirements, proposals, assumptions, and observed results accurately. Never present a proposed design as implemented or a planned check as passed.
- Keep the length and structure proportional to the work. A small bug may need a short explanation and a few acceptance conditions. Do not force every ticket into an architecture proposal or fill sections with empty boilerplate.

## Titles and descriptions

Use a concise, concrete title describing the intended change or question. Put ticket IDs and other metadata in the tracker's fields rather than cluttering the title. Avoid change tags unless the project explicitly requires them for tickets.

Include the following information when relevant, using headings only where they improve readability:

- Purpose: the problem or desired outcome, affected user or system, and why the work is needed.
- Scope: included behavior and important exclusions.
- Acceptance: observable conditions someone can verify. Explain what success means instead of "implement appropriately," "works correctly," or merely listing activities.
- Dependencies: what must be available first, the supplied release condition, and what this work enables. Explain linked tickets' relevance in words.
- References: relevant plan, decision, design, reproduction, or evidence links. Retain criterion IDs as supporting traceability, not substitutes for the requirements.

For a defect, include supplied actual versus expected behavior and reproduction conditions. For an investigation, state the question to answer and evidence expected. For broader work, summarize the agreed outcome at the supplied level of detail; do not invent implementation Tasks or detailed requirements for distant work.

If missing intent would change behavior, scope, acceptance, or dependencies, return the specific gap to the developer or responsible agent. Preserve explicit unknowns when drafting is still useful. Do not invent requirements, dates, priorities, owners, issue IDs, or completion evidence to make a ticket appear ready.

## Progress and closure

Lead an update with what changed or was learned and what that means for the work. State what remains, any blocker, and the next responsible person or role and action when known. Keep routine updates brief; do not dump execution logs or repeat the entire description.

Use evidence for status claims. Link useful verification results and identify the tested commit when relevant. Distinguish implemented, reviewed, merged, and verified in the destination when that distinction matters. Report unknown or pending results explicitly. Closure summaries describe the accepted outcome, evidence, and remaining related work; the active workflow decides whether closure is allowed.

## Example

Jargon-heavy title:

> Implement idempotent execution semantics across the ingestion orchestration lifecycle

Clearer title:

> Prevent retried imports from creating duplicate records

If the approved requirements say a retry uses the same import identifier, the description can say:

> An import may be retried after a timeout. Retrying the same import currently creates a second set of records. Make retries reuse the existing result so records are created once.
>
> Acceptance:
> - Retrying a completed import with the same import identifier creates no additional records.
> - A new import with a different identifier can still create records.

The example illustrates supplied behavior; do not infer this identifier or retry policy for another project.
