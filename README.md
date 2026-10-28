# Agent Workflows

Project-independent coding agents and shared delivery skills. Gnym's definitions and installations remain separate.

## Agents

| Agent | Responsibility |
| --- | --- |
| `workflow_coordinator` | Route project-selected roles through coding, independent testing, commit, acceptance reconciliation, repair loops, and authorized PR publication. |
| `roadmap_design` | Follow a roadmap into supporting specs, diagrams, code, and existing tickets; record an Epic planning summary and create small executable Stories after developer approval. |
| `typescript_backend_coder` | Implement bounded TypeScript backend tickets with runtime validation, accurate types, reliable side effects, focused checks, and an evidence-backed handoff. |
| `backend_tester` | Independently verify acceptance, edge, and negative cases; prioritize unit then feature tests and maintain readable workflows, factories, and clients in the project language. |

The roadmap design agent owns discovery and decomposition. The TypeScript backend coder owns implementation and focused verification. The backend tester owns independent verification and test support. The coordinator manages handoffs using the consuming project's configuration. A documentation agent has not been defined here yet. The roadmap agent does not dispatch implementation or create parallel planning documents in docs/.

## Shared skills

| Skill | Purpose |
| --- | --- |
| `workflow-commit` | Platform-independent ticket verification and tagged, concise commit messages. |
| `workflow-pr` | Tag-free ticket-linked titles, five description sections, and judgment-based sizing around a 300-line target. |
| `ticket-writing` | Plain-language ticket titles, descriptions, progress updates, and closure summaries for any tracker. |
| `workflow-youtrack` | Verified YouTrack ticket operations, progress records, and closure evidence. |

The agents use ticket-writing and workflow-pr, plus the integration skill for the consuming project's tracker. The coder and tester also use workflow-commit when commit work is authorized. Only YouTrack has an integration skill in this repository today. Another tracker requires its own available integration and operating instructions; missing access is reported rather than simulated.

## Project-owned workflow

The shared coordinator supplies delivery behavior; the consuming project selects the agents and policies. Its .agent-workflow file is the shared input to installation and runtime coordination, while AGENTS.md explains project-specific rules. An installed agent is not automatically selected, and a selected file is not proof the active chat can spawn it.

To set up a new project, copy [templates/project.agent-workflow](templates/project.agent-workflow) to PROJECT/.agent-workflow, select its coder and other roles, and provide AGENTS.md. The template deliberately leaves the coder unset so the project must choose one. Use source agent names in role mappings; the installer adds the project prefix. Use none for an unconfigured optional role. required_roles must map to actual selections, and code/test/documentation stages require their corresponding roles. Tracker integrations remain explicit skill selections, such as skill.workflow-youtrack=enabled.

```sh
bash scripts/install.sh --project /path/to/project --dry-run
bash scripts/install.sh --project /path/to/project
```

Project mode installs agents into PROJECT/.codex/agents and skills into PROJECT/.agents/skills. It reads configuration as data, never executes it, and does not rewrite AGENTS.md or create tracker settings. It rejects duplicate/unknown keys, missing required roles, unsupported stages, and manual selection/target overrides combined with --project. Existing manual installation remains available below. Re-running setup does not prune old installations; obsolete definitions may remain available but are not selected by the project mappings.

Supported stages are code, test, commit, verify_ticket, documentation, and publish_pr. The default sequence is code -> test -> commit -> verify_ticket -> publish_pr. The coordinator checks acceptance evidence for the committed candidate, returning defects to the responsible role and refreshing affected evidence after repairs. max_repair_rounds bounds repair attempts. Conditional required documentation must receive an explicit owner when no documentation agent is selected.

The template's commit/publish_pr/merge=explicit settings require authorization from the actual developer assignment or standing instructions. They do not imply another confirmation when authorization already exists. Branch policy and gates belong to the project. The default endpoint is a verified published PR, not merging or ticket closure. Installation performs setup only; it does not execute delivery or provide a deterministic workflow runner.

[Coordinator delivery loop diagram](diagrams/workflow-coordinator.mmd) · [Agent Workflows FigJam](https://www.figma.com/board/tffxiiTKRGoeBG1FHmMxKW)

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

Repeat --agent or --skill to select components. All four agents include ticket-writing and workflow-pr, which includes workflow-commit. YouTrack remains optional and includes ticket-writing when selected. With no selections, install.sh retains its shared-skills-only behavior. Selecting an agent does not automatically install a tracker integration.

For a TypeScript backend coder, select `--agent typescript_backend_coder`; for the language-agnostic tester, select `--agent backend_tester`. Repeat --agent to select any combination with the desired prefix. Selection does not dispatch agents or define their execution sequence.

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

For definitions-only selection, --agent workflow_coordinator installs the generic coordinator without choosing its worker roles. Use project mode when the installer should coordinate those selections with the project.

## Use

From a configured product project, ask:

> Have workout_workflow_coordinator deliver [verified ticket] using this project's role mappings and workflow. Follow the actual assignment's delivery permissions and report the stage reached and evidence.

For a planning assignment instead:

> Have workout_roadmap_design review the roadmap at [path or link], follow its supporting references, inspect the code and existing tickets, and propose an Epic and small Story breakdown for my review. Use [tracker project] for ticket records.

Specify authorized roadmap capture when an Epic needs to be created or updated. Detailed Stories follow approval of the proposed breakdown. The agent reports missing evidence, unresolved decisions, and blocked work rather than inventing requirements or readiness.

For an implementation assignment after the project has configured its delivery workflow:

> Have workout_typescript_backend_coder implement [verified ticket], follow the project instructions and linked acceptance criteria, run focused checks, and return evidence for independent testing. Follow the project's existing delivery permissions.

The coder's engineering baseline is strict, accurate types; runtime validation; cohesive functions/modules/classes; practical SOLID principles; explicit asynchronous and side-effect behavior; and focused tests. It does not prescribe a framework, database, branching hierarchy, or permission to publish. Project installation and assignment remain separate actions.

For an independent testing assignment:

> Have workout_backend_tester evaluate [verified ticket] against [implementation candidate]. Cover acceptance criteria, relevant edge and negative cases, prioritize unit then feature coverage, and return reproducible defects and verification evidence. Follow the project's existing delivery permissions.

The tester follows the project's language, framework, and commands. Tests mirror source structure, use behavioral scenario names, and keep assertions visible. Local helpers stay in their test file; shared workflows, factories, and clients are extracted when used across files. Vocabulary: stub for in-memory fixtures, persist for stored fixtures, call for client access, get for reads, and expect for assertions using the native framework. External clients are normally mocked outside acceptance tests; feature tests connect real internal layers where practical. Production defects return to the coder. Test and helper changes remain distinct from product fixes and overall acceptance.

## Repository contributions

Use Bash for repository scripts. Run `bash scripts/test_install.sh` for isolated skill and agent installer checks. Validate skill frontmatter and relative links when editing skills; validate TOML when editing agents.

This repository has no assigned YouTrack project; commits here use `<TAG>: <Summary>` until that changes. Repository setup does not imply a commit, global installation, or remote publication.
