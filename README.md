# Agent Workflows

Project-independent coding agents and shared delivery skills. Gnym's definitions and installations remain separate.

## Agents

| Agent | Responsibility |
| --- | --- |
| `roadmap_design` | Follow a roadmap into supporting specs, diagrams, code, and existing tickets; record an Epic planning summary and create small executable Stories after developer approval. |
| `typescript_backend_coder` | Implement bounded TypeScript backend tickets with runtime validation, accurate types, reliable side effects, focused checks, and an evidence-backed handoff. |

The roadmap design agent owns discovery and decomposition. The TypeScript backend coder owns implementation and focused verification; independent testing and documentation agents have not been defined here yet. It creates no parallel planning documents in docs/ and does not dispatch implementation.

## Shared skills

| Skill | Purpose |
| --- | --- |
| `workflow-commit` | Platform-independent ticket verification and tagged, concise commit messages. |
| `workflow-pr` | Tag-free ticket-linked titles, five description sections, and judgment-based sizing around a 300-line target. |
| `ticket-writing` | Plain-language ticket titles, descriptions, progress updates, and closure summaries for any tracker. |
| `workflow-youtrack` | Verified YouTrack ticket operations, progress records, and closure evidence. |

The agents use ticket-writing and workflow-pr, plus the integration skill for the consuming project's tracker. The coder also uses workflow-commit when commit work is authorized. Only YouTrack has an integration skill in this repository today. Another tracker requires its own available integration and operating instructions; missing access is reported rather than simulated.

## Installation

List available agents and skills:

```sh
bash scripts/install.sh --list
```

Select an agent, give its installation a project prefix, and optionally include a tracker skill:

```sh
bash scripts/install.sh --agent roadmap_design --prefix workout --skill workflow-youtrack --dry-run
bash scripts/install.sh --agent roadmap_design --prefix workout --skill workflow-youtrack
```

This installs `workout_roadmap_design.toml` with `name = "workout_roadmap_design"`. Only the agent's filename and identity change; its approved instructions and all shared skill names remain unchanged. A prefix labels the installation; it does not bind it to a repository path or configure a tracker project. Prefixes start with a lowercase letter and contain lowercase letters, digits, or underscores. Omit --prefix to install the original agent name. Multiple project prefixes can coexist.

Repeat --agent or --skill to select components. Both agents include ticket-writing and workflow-pr, which includes workflow-commit. YouTrack remains optional and includes ticket-writing when selected. With no selections, install.sh retains its shared-skills-only behavior. Selecting an agent does not automatically install a tracker integration.

For a TypeScript backend coder, select `--agent typescript_backend_coder` with the desired prefix. Selecting both agents is supported; it does not dispatch either one or define their execution sequence.

Both agent and skill conflicts are checked before either destination is changed. Identical installations are left alone; differing installations require --force after reviewing the differences. Preview with --dry-run. Runtime failures may still leave earlier reported installations complete; this is not an all-or-nothing transaction.

Install selected skills alone:

```sh
bash scripts/install.sh --skill workflow-commit
```

For definitions alone, without installing skill dependencies:

```sh
bash scripts/install_agents.sh --agent roadmap_design --prefix workout --dry-run
```

Both scripts respect CODEX_HOME (default ~/.codex). The main installer accepts --target DIRECTORY for skills and --agents-target DIRECTORY for agents. The definitions-only installer uses --target DIRECTORY for agents. Preview and --list do not create destination directories. The repository source files and existing unprefixed installations are preserved.

Agent definitions use the standalone TOML format described in the [official OpenAI documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents). They inherit the parent session's model, permissions, and connected tools. The roadmap agent's repository read-only behavior is an instruction boundary, not a separate permissions override.

## Use

From the consuming product repository, ask:

> Have workout_roadmap_design review the roadmap at [path or link], follow its supporting references, inspect the code and existing tickets, and propose an Epic and small Story breakdown for my review. Use [tracker project] for ticket records.

Specify authorized roadmap capture when an Epic needs to be created or updated. Detailed Stories follow approval of the proposed breakdown. The agent reports missing evidence, unresolved decisions, and blocked work rather than inventing requirements or readiness.

For an implementation assignment after the project has configured its delivery workflow:

> Have workout_typescript_backend_coder implement [verified ticket], follow the project instructions and linked acceptance criteria, run focused checks, and return evidence for independent testing. Follow the project's existing delivery permissions.

The coder's engineering baseline is strict, accurate types; runtime validation; cohesive functions/modules/classes; practical SOLID principles; explicit asynchronous and side-effect behavior; and focused tests. It does not prescribe a framework, database, branching hierarchy, or permission to publish. Project installation and assignment remain separate actions.

## Repository contributions

Use Bash for repository scripts. Run `bash scripts/test_install.sh` for isolated skill and agent installer checks. Validate skill frontmatter and relative links when editing skills; validate TOML when editing agents.

This repository has no assigned YouTrack project; commits here use `<TAG>: <Summary>` until that changes. Repository setup does not imply a commit, global installation, or remote publication.
