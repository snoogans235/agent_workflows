#!/usr/bin/env bash
# Behavioral checks using isolated targets; no global installation or network access.
set -euo pipefail
scripts_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_dir="$(cd -- "$scripts_dir/../skills" && pwd -P)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/agent-workflows-test.XXXXXX")"
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
target="$scratch/target with spaces/skills"
output="$scratch/output"
fail() { echo "FAIL: $*" >&2; exit 1; }
run() { bash "$scripts_dir/install.sh" --target "$target" "$@" >"$output" 2>&1 || { cat "$output" >&2; fail 'Unexpected installer failure'; }; }
reject() {
    local code=0
    bash "$scripts_dir/install.sh" --target "$target" "$@" >"$output" 2>&1 || code=$?
    [[ "$code" == 2 ]] || { cat "$output" >&2; fail "Expected rejection, received $code"; }
}
run --dry-run
[[ ! -e "$target" ]] || fail 'Preview wrote files'
run --skill workflow-commit
[[ -d "$target/workflow-commit" && ! -e "$target/workflow-youtrack" && ! -e "$target/workflow-pr" ]] || fail 'Commit selection installed unrelated skills'
echo 'PASS: commit installs independently of any tracker skill'
run --skill workflow-pr --skill workflow-pr
[[ -d "$target/workflow-pr" && ! -e "$target/workflow-youtrack" ]] || fail 'PR selection installed a tracker skill'
diff -qr "$source_dir/workflow-commit" "$target/workflow-commit" >/dev/null || fail 'Missing or different commit dependency'
diff -qr "$source_dir/workflow-pr" "$target/workflow-pr" >/dev/null || fail 'Different PR installation'
echo 'PASS: PR dependencies remain tracker-independent'
run --skill workflow-youtrack
[[ -d "$target/ticket-writing" ]] || fail 'YouTrack selection omitted ticket writing'
diff -qr "$source_dir/ticket-writing" "$target/ticket-writing" >/dev/null || fail 'Different ticket-writing installation'
echo 'PASS: YouTrack includes platform-independent ticket writing'
run
for skill in "$source_dir"/*; do
    diff -qr "$skill" "$target/$(basename -- "$skill")" >/dev/null || fail 'Missing dependency or different installation'
done
run
[[ "$(grep -c '^unchanged ' "$output")" == 4 ]] || fail 'Repeat install changed skills'
echo 'PASS: preview, dependencies, duplicate selections, paths with spaces, repeat install'

printf '\nLocal edit\n' >> "$target/workflow-commit/SKILL.md"
rm -rf -- "$target/workflow-pr"
reject
[[ ! -e "$target/workflow-pr" ]] || fail 'Conflict preflight wrote another skill'
run --force --dry-run
grep -q 'Local edit' "$target/workflow-commit/SKILL.md" || fail 'Preview replaced local edits'
run --force
diff -qr "$source_dir/workflow-commit" "$target/workflow-commit" >/dev/null || fail 'Replacement differs'
[[ -d "$target/workflow-pr" ]] || fail 'Missing skill was not restored'
echo 'PASS: conflict preflight and explicit replacement'

reject --skill unknown
reject --skill ../README.md
reject --target
reject --skill
reject --target /
reject --target "$HOME"
reject --target "$source_dir/new/../skills"
reject --target "$source_dir"
echo 'PASS: invalid selection, missing values, unsafe and overlapping targets'

rm -rf -- "$target/workflow-commit"
ln -s "$source_dir/workflow-commit" "$target/workflow-commit"
reject --force
[[ -L "$target/workflow-commit" ]] || fail 'Replaced symlink'
rm -- "$target/workflow-commit"
printf 'Existing file\n' > "$target/workflow-commit"
reject --force
grep -q 'Existing file' "$target/workflow-commit" || fail 'Replaced regular file'
echo 'PASS: symlink and non-directory protection'


agent_target="$scratch/agent target"
agent_installer="$scripts_dir/install_agents.sh"
agent_source="$scripts_dir/../agents/roadmap_design.toml"
bash "$agent_installer" --target "$agent_target" --dry-run >"$output"
[[ ! -e "$agent_target" ]] || fail 'Agent preview wrote files'
bash "$agent_installer" --target "$agent_target" >"$output"
cmp -s "$agent_source" "$agent_target/roadmap_design.toml" || fail 'Agent installation differs'
bash "$agent_installer" --target "$agent_target" >"$output"
grep -q '^unchanged ' "$output" || fail 'Repeat agent install changed files'
printf '\n# Local edit\n' >> "$agent_target/roadmap_design.toml"
code=0
bash "$agent_installer" --target "$agent_target" >"$output" 2>&1 || code=$?
[[ "$code" == 2 ]] || fail 'Agent conflict was not rejected'
bash "$agent_installer" --target "$agent_target" --force --dry-run >"$output"
grep -q 'Local edit' "$agent_target/roadmap_design.toml" || fail 'Agent preview overwrote edits'
bash "$agent_installer" --target "$agent_target" --force >"$output"
cmp -s "$agent_source" "$agent_target/roadmap_design.toml" || fail 'Agent replacement differs'
rm -- "$agent_target/roadmap_design.toml"
ln -s "$agent_source" "$agent_target/roadmap_design.toml"
code=0
bash "$agent_installer" --target "$agent_target" --force >"$output" 2>&1 || code=$?
[[ "$code" == 2 && -L "$agent_target/roadmap_design.toml" ]] || fail 'Agent symlink was not protected'
echo 'PASS: agent preview, install, repeat install, conflict, replacement, and symlink protection'


selected_skills="$scratch/selected/skills"
selected_agents="$scratch/selected/agents"
select_install() {
    bash "$scripts_dir/install.sh" --target "$selected_skills" --agents-target "$selected_agents" "$@" >"$output" 2>&1 || { cat "$output" >&2; fail 'Selected installation failed'; }
}
select_reject() {
    local status=0
    bash "$scripts_dir/install.sh" --target "$selected_skills" --agents-target "$selected_agents" "$@" >"$output" 2>&1 || status=$?
    [[ "$status" == 2 ]] || { cat "$output" >&2; fail "Expected selected-install rejection, received $status"; }
}
select_install --list
grep -q '^roadmap_design$' "$output" || fail 'Inventory omitted agent'
[[ ! -e "$selected_skills" && ! -e "$selected_agents" ]] || fail 'Inventory wrote files'
select_install --agent roadmap_design --prefix workout --dry-run
[[ ! -e "$selected_skills" && ! -e "$selected_agents" ]] || fail 'Combined preview wrote files'
select_reject --prefix workout
select_reject --agent unknown --prefix workout
select_reject --agent roadmap_design --prefix '../unsafe'
select_reject --agent roadmap_design --prefix 'bad prefix'
select_reject --agent roadmap_design --prefix
[[ ! -e "$selected_skills" && ! -e "$selected_agents" ]] || fail 'Invalid input wrote files'
select_install --agent roadmap_design --agent roadmap_design --prefix workout --skill workflow-youtrack
installed_agent="$selected_agents/workout_roadmap_design.toml"
[[ -f "$installed_agent" && ! -e "$selected_agents/roadmap_design.toml" ]] || fail 'Incorrect prefixed filename'
grep -Fqx 'name = "workout_roadmap_design"' "$installed_agent" || fail 'Incorrect prefixed identity'
diff -u <(tail -n +2 "$agent_source") <(tail -n +2 "$installed_agent") || fail 'Prefix changed approved agent behavior'
for skill in workflow-commit workflow-pr ticket-writing workflow-youtrack; do
    diff -qr "$source_dir/$skill" "$selected_skills/$skill" >/dev/null || fail 'Shared skill renamed or changed'
done
[[ ! -e "$selected_skills/workout_ticket-writing" ]] || fail 'Skill was prefixed'
select_install --agent roadmap_design --prefix workout --skill workflow-youtrack
[[ "$(grep -c '^unchanged ' "$output")" == 5 ]] || fail 'Prefixed repeat install changed files'
select_install --agent roadmap_design --prefix another_project
[[ -f "$selected_agents/another_project_roadmap_design.toml" && -f "$installed_agent" ]] || fail 'Project installations did not coexist'
# Preflight must preserve all other destinations if either component type conflicts.
printf '\n# Local edit\n' >> "$installed_agent"
rm -rf -- "$selected_skills/workflow-pr"
select_reject --agent roadmap_design --prefix workout
[[ ! -e "$selected_skills/workflow-pr" ]] || fail 'Agent conflict allowed skill writes'
select_install --agent roadmap_design --prefix workout --force --dry-run
grep -q 'Local edit' "$installed_agent" || fail 'Preview replaced edited agent'
select_install --agent roadmap_design --prefix workout --force
grep -q 'Local edit' "$installed_agent" && fail 'Force failed to replace agent'
printf '\nLocal edit\n' >> "$selected_skills/workflow-commit/SKILL.md"
select_reject --agent roadmap_design --prefix fresh
[[ ! -e "$selected_agents/fresh_roadmap_design.toml" ]] || fail 'Skill conflict allowed agent writes'
echo 'PASS: selections, agent-only prefixes, unchanged instructions, shared skills, project coexistence, and combined conflict preflight'

# Selecting a coder installs its shared skills, without selecting a tracker or another agent.
coder_skills="$scratch/coder/skills"
coder_agents="$scratch/coder/agents"
coder_source="$scripts_dir/../agents/typescript_backend_coder.toml"
bash "$scripts_dir/install.sh" --target "$coder_skills" --agents-target "$coder_agents" \
    --agent typescript_backend_coder --prefix workout --dry-run >"$output"
[[ ! -e "$coder_skills" && ! -e "$coder_agents" ]] || fail 'Coder preview wrote files'
bash "$scripts_dir/install.sh" --target "$coder_skills" --agents-target "$coder_agents" \
    --agent typescript_backend_coder --prefix workout >"$output"
coder_installed="$coder_agents/workout_typescript_backend_coder.toml"
grep -Fqx 'name = "workout_typescript_backend_coder"' "$coder_installed" || fail 'Incorrect coder identity'
diff -u <(tail -n +2 "$coder_source") <(tail -n +2 "$coder_installed") || fail 'Coder instructions changed during installation'
[[ ! -e "$coder_agents/workout_roadmap_design.toml" && ! -e "$coder_skills/workflow-youtrack" ]] || fail 'Coder selection installed unrelated components'
for skill in ticket-writing workflow-pr workflow-commit; do
    diff -qr "$source_dir/$skill" "$coder_skills/$skill" >/dev/null || fail 'Missing or different coder dependency'
done
bash "$scripts_dir/install.sh" --target "$coder_skills" --agents-target "$coder_agents" \
    --agent typescript_backend_coder --prefix workout >"$output"
[[ "$(grep -c '^unchanged ' "$output")" == 4 ]] || fail 'Repeat coder install changed files'
bash "$scripts_dir/install.sh" --target "$coder_skills" --agents-target "$coder_agents" \
    --agent typescript_backend_coder --agent roadmap_design --prefix workout >"$output"
[[ -f "$coder_installed" && -f "$coder_agents/workout_roadmap_design.toml" ]] || fail 'Multiple-agent selection failed'
echo 'PASS: coder selection, preview, prefix, intact instructions, dependencies, tracker independence, and repeat installation'

# The language-agnostic tester remains selectable without a coder or tracker.
tester_skills="$scratch/tester/skills"
tester_agents="$scratch/tester/agents"
tester_source="$scripts_dir/../agents/backend_tester.toml"
bash "$scripts_dir/install.sh" --list >"$output"
grep -Fqx 'backend_tester' "$output" || fail 'Inventory omitted backend tester'
bash "$scripts_dir/install.sh" --target "$tester_skills" --agents-target "$tester_agents" \
    --agent backend_tester --prefix workout --dry-run >"$output"
[[ ! -e "$tester_skills" && ! -e "$tester_agents" ]] || fail 'Tester preview wrote files'
bash "$scripts_dir/install.sh" --target "$tester_skills" --agents-target "$tester_agents" \
    --agent backend_tester --prefix workout >"$output"
tester_installed="$tester_agents/workout_backend_tester.toml"
grep -Fqx 'name = "workout_backend_tester"' "$tester_installed" || fail 'Incorrect tester identity'
diff -u <(tail -n +2 "$tester_source") <(tail -n +2 "$tester_installed") || fail 'Tester instructions changed during installation'
[[ ! -e "$tester_agents/workout_roadmap_design.toml" && ! -e "$tester_agents/workout_typescript_backend_coder.toml" && ! -e "$tester_skills/workflow-youtrack" ]] || fail 'Tester selection installed unrelated components'
for skill in ticket-writing workflow-pr workflow-commit; do
    diff -qr "$source_dir/$skill" "$tester_skills/$skill" >/dev/null || fail 'Missing or different tester dependency'
done
bash "$scripts_dir/install.sh" --target "$tester_skills" --agents-target "$tester_agents" \
    --agent backend_tester --prefix workout >"$output"
[[ "$(grep -c '^unchanged ' "$output")" == 4 ]] || fail 'Repeat tester install changed files'
bash "$scripts_dir/install.sh" --target "$tester_skills" --agents-target "$tester_agents" \
    --agent roadmap_design --agent typescript_backend_coder --agent backend_tester --prefix workout >"$output"
for agent in roadmap_design typescript_backend_coder backend_tester; do
    [[ -f "$tester_agents/workout_$agent.toml" ]] || fail 'Three-agent selection failed'
done
echo 'PASS: backend tester inventory, selection, preview, prefix, intact instructions, dependencies, tracker independence, and combined installation'

# Project installation is driven by role mappings, not incidental installed agents.
project_target="$scratch/project with spaces"
mkdir -p "$project_target"
printf '# Test project workflow\n' > "$project_target/AGENTS.md"
cat > "$project_target/.agent-workflow" <<'CONFIG'
prefix=sample
role.coordinator=workflow_coordinator
role.planner=roadmap_design
role.coder=typescript_backend_coder
role.tester=backend_tester
role.documenter=none
required_roles=coordinator,coder,tester
stages=code,test,commit,verify_ticket,publish_pr
base_branch=main
branch_policy=ticket_branch
documentation=when_required
max_repair_rounds=3
commit=explicit
publish_pr=explicit
merge=explicit
skill.workflow-youtrack=enabled
CONFIG
cp "$project_target/.agent-workflow" "$scratch/valid-project-config"
project_run() {
    bash "$scripts_dir/install.sh" --project "$project_target" "$@" >"$output" 2>&1 || { cat "$output" >&2; fail 'Project installation failed'; }
}
project_reject() {
    local status=0
    bash "$scripts_dir/install.sh" --project "$project_target" "$@" >"$output" 2>&1 || status=$?
    [[ "$status" == 2 ]] || { cat "$output" >&2; fail "Expected project rejection, received $status"; }
}
project_run --dry-run
[[ ! -e "$project_target/.agents" && ! -e "$project_target/.codex" ]] || fail 'Project preview wrote files'
project_reject --prefix other
project_reject --skill workflow-commit
project_reject --agents-target "$scratch/unsafe-override"
sed 's/role.tester=backend_tester/role.tester=none/' "$scratch/valid-project-config" > "$project_target/.agent-workflow"
project_reject
sed 's/role.coder=typescript_backend_coder/role.coder=unknown/' "$scratch/valid-project-config" > "$project_target/.agent-workflow"
project_reject
sed 's/stages=code,test,commit,verify_ticket,publish_pr/stages=code,documentation,publish_pr/' "$scratch/valid-project-config" > "$project_target/.agent-workflow"
project_reject
cp "$scratch/valid-project-config" "$project_target/.agent-workflow"
printf '\nprefix=duplicate\n' >> "$project_target/.agent-workflow"
project_reject
cp "$scratch/valid-project-config" "$project_target/.agent-workflow"
printf '\nbase_branch=$(touch should-not-execute)\n' >> "$project_target/.agent-workflow"
project_reject
[[ ! -e "$project_target/.agents" && ! -e "$project_target/.codex" ]] || fail 'Invalid project configuration wrote files'
cp "$scratch/valid-project-config" "$project_target/.agent-workflow"
project_run
for agent in workflow_coordinator roadmap_design typescript_backend_coder backend_tester; do
    installed="$project_target/.codex/agents/sample_$agent.toml"
    [[ -f "$installed" ]] || fail 'Project role was not installed'
    grep -Fqx "name = \"sample_$agent\"" "$installed" || fail 'Project role has incorrect identity'
    diff -u <(tail -n +2 "$scripts_dir/../agents/$agent.toml") <(tail -n +2 "$installed") || fail 'Project install changed agent instructions'
done
for skill in ticket-writing workflow-commit workflow-pr workflow-youtrack; do
    diff -qr "$source_dir/$skill" "$project_target/.agents/skills/$skill" >/dev/null || fail 'Project skill differs'
done
project_run
[[ "$(grep -c '^unchanged ' "$output")" == 8 ]] || fail 'Repeat project setup changed components'
cmp -s "$scratch/valid-project-config" "$project_target/.agent-workflow" || fail 'Installer changed project configuration'
[[ "$(cat "$project_target/AGENTS.md")" == '# Test project workflow' ]] || fail 'Installer rewrote project instructions'
echo 'PASS: project role coordination, required roles, project-local targets, safe config parsing, dependency installation, and repeat setup'

coordinator_skills="$scratch/coordinator/skills"
coordinator_agents="$scratch/coordinator/agents"
bash "$scripts_dir/install.sh" --target "$coordinator_skills" --agents-target "$coordinator_agents" \
    --agent workflow_coordinator --prefix sample >"$output"
[[ -f "$coordinator_agents/sample_workflow_coordinator.toml" ]] || fail 'Coordinator selection did not install coordinator'
[[ ! -e "$coordinator_agents/sample_backend_tester.toml" && ! -e "$coordinator_agents/sample_typescript_backend_coder.toml" && ! -e "$coordinator_skills/workflow-youtrack" ]] || fail 'Coordinator hard-coded worker or tracker dependencies'
echo 'PASS: standalone coordinator does not choose workers or tracker'
echo 'All installer checks passed.'
