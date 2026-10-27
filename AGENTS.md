# Agent Workflows repository

This repository owns reusable workflow instructions and shared skills, not consuming projects' product decisions or documentation.

- Use Bash for repository scripts; do not introduce Python scripts.

- Keep project-specific settings in each consuming project's `docs/workflow.md`.
- Keep shared commit, PR, and YouTrack policy in their owning skills; workflow-specific branching and sequencing belong to that workflow.
- Preserve existing Gnym definitions and installed skills unless explicitly asked to migrate them.
- This repository currently has no YouTrack project. Use ticket-free `<TAG>: <Summary>` commits here; do not extend that exception to tracked product repositories.
- Verify new/changed skills with the Skill Creator validator when available. Validate links and exercise installer behavior in an isolated temporary target. Report unavailable checks accurately.
- Workflow setup does not authorize a commit, push, PR, merge, live YouTrack mutation, or global installation by itself. Reuse explicit authorization already given for those actions.
