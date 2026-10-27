# Agent Workflows

A home for project-independent coding agents and shared delivery skills. Workflows will be agent-driven; agent definitions and responsibilities are pending design review. No workflow agents are implemented yet.

## Shared skills under review

| Skill | Purpose |
| --- | --- |
| `workflow-commit` | Ticket-linked commits with consistent tags and concise changelog summaries. |
| `workflow-pr` | Small, evidence-backed PRs with consistent titles and five description sections. |
| `ticket-writing` | Plain-language ticket titles, descriptions, progress updates, and closure summaries for any tracker. |

| `workflow-youtrack` | Verified issue operations, progress records, and closure evidence. |

Gnym's definitions and installations remain separate. The shared skills are local drafts pending review; adopting them does not require a particular workflow or branch hierarchy.

## Install shared skills

```sh
bash scripts/install.sh --dry-run
bash scripts/install.sh
```

The installer adds missing skills, leaves identical copies alone, and refuses differing copies unless `--force` is supplied. It does not install agent roles or change project repositories. Use `--target DIRECTORY` for a custom skills directory, or repeat `--skill NAME` to select skills. Selecting a skill includes its shared dependencies. The commit skill installs independently; the PR skill includes the commit skill. YouTrack is optional and is installed only when selected explicitly or when installing all skills; selecting it includes ticket-writing. The ticket-writing skill also installs independently.

## Repository contributions

Use Bash for repository scripts. Run `bash scripts/test_install.sh` for isolated installer checks. Validate skill frontmatter and relative links when editing skills.

This repository has no assigned YouTrack project; commits here use `<TAG>: <Summary>` until that changes. Repository setup does not imply a commit or remote publication.
