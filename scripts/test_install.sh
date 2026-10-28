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
echo 'All installer checks passed.'
