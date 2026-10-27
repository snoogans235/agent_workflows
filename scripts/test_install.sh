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

echo 'All installer checks passed.'
