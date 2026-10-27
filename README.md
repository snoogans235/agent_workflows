# Agent Workflows

Project-independent coding agents and shared delivery skills. Gnym's definitions and installations remain separate.

## Agents

| Agent | Responsibility |
| --- | --- |
| `roadmap_design` | Follow a roadmap into supporting specs, diagrams, code, and existing tickets; record an Epic planning summary and create small executable Stories after developer approval. |

The roadmap design agent owns discovery and decomposition. Coding, testing, and documentation are separate responsibilities; those agents have not been defined here yet. It creates no parallel planning documents in docs/ and does not dispatch implementation.

## Shared skills

| Skill | Purpose |
| --- | --- |
| `workflow-commit` | Platform-independent ticket verification and tagged, concise commit messages. |
| `workflow-pr` | Tag-free ticket-linked titles, five description sections, and judgment-based sizing around a 300-line target. |
| `ticket-writing` | Plain-language ticket titles, descriptions, progress updates, and closure summaries for any tracker. |
| `workflow-youtrack` | Verified YouTrack ticket operations, progress records, and closure evidence. |

The agent uses ticket-writing and workflow-pr's sizing guidance, plus the integration skill for the consuming project's tracker. Only YouTrack has an integration skill in this repository today. Another tracker requires its own available integration and operating instructions; missing access is reported rather than simulated.

## Installation

Preview and install shared skills:

```sh
bash scripts/install.sh --dry-run
bash scripts/install.sh
```

Preview and install agent definitions:

```sh
bash scripts/install_agents.sh --dry-run
bash scripts/install_agents.sh
```

Both installers respect CODEX_HOME (default ~/.codex), leave identical copies alone, and refuse differing copies unless --force is supplied. Use --target DIRECTORY to select a custom skills or agents directory for the corresponding installer. The skills installer also accepts repeated --skill NAME selections and includes shared dependencies. Commit installs independently; PR includes commit; YouTrack includes ticket-writing. Ticket-writing also installs independently. The agents installer installs definitions only; it does not select a tracker or install skills.

Agent definitions use the standalone TOML format described in the [official OpenAI documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents). They inherit the parent session's model, permissions, and connected tools. The roadmap agent's repository read-only behavior is an instruction boundary, not a separate permissions override.

## Use

From the consuming product repository, ask:

> Have roadmap_design review the roadmap at [path or link], follow its supporting references, inspect the code and existing tickets, and propose an Epic and small Story breakdown for my review. Use [tracker project] for ticket records.

Specify authorized roadmap capture when an Epic needs to be created or updated. Detailed Stories follow approval of the proposed breakdown. The agent reports missing evidence, unresolved decisions, and blocked work rather than inventing requirements or readiness.

## Repository contributions

Use Bash for repository scripts. Run `bash scripts/test_install.sh` for isolated skill and agent installer checks. Validate skill frontmatter and relative links when editing skills; validate TOML when editing agents.

This repository has no assigned YouTrack project; commits here use `<TAG>: <Summary>` until that changes. Repository setup does not imply a commit, global installation, or remote publication.
