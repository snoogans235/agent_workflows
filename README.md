# Agent Workflows

Project-independent coding agents and shared delivery skills. Gnym's definitions and installations remain separate.

## Agents

| Agent | Responsibility |
| --- | --- |
| `workflow_coordinator` | Route project-selected roles through coding, independent testing, commit, acceptance reconciliation, audience-specific documentation, repair loops, and authorized PR publication. |
| `roadmap_design` | Follow roadmap sources, record accepted technical designs/decisions in shared references, and keep approved decomposition in the Epic and small Stories. |
| `typescript_backend_coder` | Implement bounded TypeScript backend tickets with runtime validation, accurate types, reliable side effects, focused checks, and an evidence-backed handoff. |
| `backend_tester` | Independently verify acceptance, edge, and negative cases; prioritize unit then feature tests and maintain readable workflows, factories, and clients in the project language. |
| `agent_documenter` | Curate focused technical context for agents: decisions, invariants, quirks, preferred approaches, and grounded references, with a small AGENTS.md entry point. |
| `internal_documenter` | Help developers and maintainers build, extend, debug, and operate the system, with common tasks first and deeper reference available when needed. |
| `user_documenter` | Help end users get started, complete common tasks, explore advanced usage, and troubleshoot supported product behavior. |

The roadmap design agent owns discovery and decomposition. The TypeScript backend coder owns implementation and focused verification. The backend tester owns independent verification and test support. The coordinator manages handoffs using the consuming project's configuration. The agents-audience documenter maintains focused technical context; the internal documenter writes developer/maintainer guides. The user documenter owns end-user product guides. The roadmap agent does not dispatch implementation or create parallel planning documents in docs/.

## Shared skills

| Skill | Purpose |
| --- | --- |
| `workflow-commit` | Platform-independent ticket verification and tagged, concise commit messages. |
| `workflow-pr` | Tag-free ticket-linked titles, five description sections, and judgment-based sizing around a 300-line target. |
| `ticket-writing` | Plain-language ticket titles, descriptions, progress updates, and closure summaries for any tracker. |
| `workflow-youtrack` | Verified YouTrack ticket operations, progress records, and closure evidence. |

The agents use ticket-writing and workflow-pr, plus the integration skill for the consuming project's tracker. The coder, tester, and documenter also use workflow-commit when commit work is authorized. Only YouTrack has an integration skill in this repository today. Another tracker requires its own available integration and operating instructions; missing access is reported rather than simulated.

## Documentation locations

| Location | Content and audience |
| --- | --- |
| Root AGENTS.md | Essential agent instructions and short task-oriented references |
| Root README.md | Project introduction and links to audience entry points |
| docs/agents/ | Focused agent context, quirks, preferences, and navigation |
| docs/internal/ | Developer/maintainer setup, common tasks, extension, debugging, and operations |
| docs/users/ | End-user getting started, task guides, advanced use, and troubleshooting |
| docs/reference/ | Authoritative shared designs, decisions, architecture, contracts, data models, and invariants |

Create these locations and indexes only when content needs them. Preserve useful existing layouts until a scoped move is assigned. Shared facts live once in reference material, linked from audience guides. Give each shared-reference change a single file owner to avoid competing edits or explanations.

The roadmap agent writes accepted technical designs/decisions to docs/reference/, keeping their planned-versus-implemented status explicit. Its proposed breakdown, coverage, execution status, and approval of ticket decomposition remain in the Epic and Stories. It does not create duplicate planning documents or write the audience guides. Documentation agents update references within their assigned scope and maintain the links readers need.

## Project-owned workflow

The shared coordinator supplies delivery behavior; the consuming project selects the agents and policies. Its .agent-workflow file is the shared input to installation and runtime coordination, while AGENTS.md explains project-specific rules. An installed agent is not automatically selected, and a selected file is not proof the active chat can spawn it.

To set up a new project, copy [templates/project.agent-workflow](templates/project.agent-workflow) to PROJECT/.agent-workflow, select its coder and other roles, and provide AGENTS.md. The template deliberately leaves the coder unset so the project must choose one. Use a source agent name or a comma-separated candidate list in each role mapping; the installer adds the project prefix to every selected agent. Use none for an unconfigured optional role. required_roles must map to actual selections, and code/test/documentation stages require their corresponding roles. Tracker integrations remain explicit skill selections, such as skill.workflow-youtrack=enabled.

```sh
bash scripts/install.sh --project /path/to/project --dry-run
bash scripts/install.sh --project /path/to/project
```

Project mode installs agents into PROJECT/.codex/agents and skills into PROJECT/.agents/skills. It reads configuration as data, never executes it, and does not rewrite AGENTS.md or create tracker settings. It rejects duplicate/unknown keys, missing required roles, unsupported stages, and manual selection/target overrides combined with --project. Existing manual installation remains available below. Re-running setup does not prune old installations; obsolete definitions may remain available but are not selected by the project mappings.

### Multiple agents per role

A role can have multiple candidates, with explicit routes by project-defined scope:

```ini
role.coder=typescript_backend_coder,typescript_frontend_coder
route.coder.backend=typescript_backend_coder
route.coder.frontend=typescript_frontend_coder
```

This is an illustrative backend/frontend mapping: a frontend agent has not been defined in this repository yet. All selected agents must exist in the catalog before installation succeeds. Define and register the frontend agent before enabling this example. No frontend behavior is supplied by the backend coder.

Use route.ROLE.SCOPE for each candidate in a multi-agent role. Every candidate needs at least one route; routes must select a member of that role. Route declarations can precede or follow role declarations. Duplicate members, empty list entries, mixing none with agents, duplicate route keys, and missing or invalid routes are rejected before destination writes. An agent selected by multiple roles is installed once, and skill dependencies are also deduplicated. Existing single-agent mappings remain valid without routes.

AGENTS.md defines how ticket scope, explicit assignments, and source boundaries correspond to scope labels. The coordinator chooses an eligible explicitly assigned agent or the matching route, never the first candidate by list order. A route.ROLE.default is an optional fallback for unscoped work only when no narrower scope can be established; an explicitly named but unmapped scope remains a gap. Coder and tester routes are independent selections and must both fit the assignment.

For a ticket spanning backend and frontend, the coordinator bounds each assignment, establishes shared interfaces, file ownership, dependencies, an integration owner, and independent evidence for the combined result. Multiple candidates do not automatically imply parallel execution; the project/assignment must authorize it and ownership must permit it. Ambiguous routing returns for clarification. Configuration validation checks declarations; the coordinator performs routing at runtime rather than a deterministic script choosing workers.

Supported stages are code, test, commit, verify_ticket, documentation, and publish_pr. The default sequence is code -> test -> commit -> verify_ticket -> publish_pr. The coordinator checks acceptance evidence for the committed candidate, returning defects to the responsible role and refreshing affected evidence after repairs. max_repair_rounds bounds repair attempts. Conditional required documentation must receive an explicit owner when no suitable audience agent is selected. Route agents-audience context to agent_documenter, internal guides to internal_documenter, and end-user guides to user_documenter.

With documentation=when_required, the default flow assesses documentation and finishes required updates after ticket verification, immediately before PR publication: code -> test -> commit -> verify ticket -> documentation -> publish PR. This is a publication-readiness check even when documentation is not a separately listed stage. Projects that want an explicit stage can use stages=code,test,commit,verify_ticket,documentation,publish_pr after selecting a suitable documenter role. Documentation changes receive an authorized follow-up commit and affected checks before publication. The coordinator respects project stage choices and surfaces conflicts with required coverage rather than silently rewriting the workflow.

Documentation impact is assessed separately for agents, internal, and users; these audience scopes are independent of backend/frontend scopes. Only impacted audiences receive assignments, and an explained no-update result is valid. Shared reference and navigation files have one assigned owner. Required updates travel with the implementation PR, with affected checks refreshed for the final candidate. Missing required audience ownership blocks readiness. After merge, documentation-site publication and release availability checks are separate project-assigned actions; merging does not prove deployment.

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

Repeat --agent or --skill to select components. All seven agents include ticket-writing and workflow-pr, which includes workflow-commit. YouTrack remains optional and includes ticket-writing when selected. With no selections, install.sh retains its shared-skills-only behavior. Selecting an agent does not automatically install a tracker integration.

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

For agent-context documentation:

> Have sample_agent_documenter review [verified change or accepted decision] and update the minimum agent-facing technical context. Keep AGENTS.md small, reuse canonical references, verify source links, and report the documentation disposition and remaining gaps.

Projects can select this audience with:

```ini
role.documenter=agent_documenter
route.documenter.agents=agent_documenter
```

The agent chooses no update, touch-up, extension, or new capability coverage based on impact and existing documentation. It preserves accepted decisions, invariants, quirks/workarounds, and preferred approaches without turning tickets or transcripts into an ever-growing reference dump. It verifies facts and navigation and records the outcome in the ticket. Project source locations and publication permissions remain project-owned. Selecting this role does not automatically add a documentation stage or install it into existing projects.

Clear topic headings, scoped facts, canonical source links, and freshness/status distinctions can support later retrieval-augmented generation. This repository does not implement embeddings, indexing, or a RAG service; those are separate work.

For internal documentation:

> Have sample_internal_documenter review [verified change] and update the developer/maintainer guidance. Lead with the simplest useful setup or common task, add advanced material only where needed, and link shared contracts in docs/reference/. Verify safe examples and report untested claims or gaps.

To select both documentation audiences:

```ini
role.documenter=agent_documenter,internal_documenter
route.documenter.agents=agent_documenter
route.documenter.internal=internal_documenter
```

The project defines scope classification and required documentation stages. The internal agent owns guides under docs/internal/ and assigned shared references, with a quick-start -> common-tasks -> advanced-use -> deep-reference reading progression. This does not require four files or new boilerplate for every change. Consequential warnings appear before the action they affect. Code comments/docstrings are included only when assigned or required by project policy. End-user documentation is owned by user_documenter.

For end-user documentation:

> Have sample_user_documenter review [verified user-facing change] and update docs/users/. Start with the shortest useful path and common tasks, then advanced usage and troubleshooting. Match the actual supported interface, verify safe examples, and report any unverified claims.

To select all three documentation audiences:

```ini
role.documenter=agent_documenter,internal_documenter,user_documenter
route.documenter.agents=agent_documenter
route.documenter.internal=internal_documenter
route.documenter.users=user_documenter
```

The user documenter explains goals, prerequisites, steps, expected results, limitations, and recovery without requiring readers to know the implementation. It follows the same impact-based documentation depth, reuses shared facts in docs/reference/, and does not imply a GUI for a CLI/API/conversational product. Selecting an audience does not itself require a docs change or authorize publishing anything.

## Repository contributions

Use Bash for repository scripts. Run `bash scripts/test_install.sh` for isolated skill and agent installer checks. Validate skill frontmatter and relative links when editing skills; validate TOML when editing agents.

This repository has no assigned YouTrack project; commits here use `<TAG>: <Summary>` until that changes. Repository setup does not imply a commit, global installation, or remote publication.
