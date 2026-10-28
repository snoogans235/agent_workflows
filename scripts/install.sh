#!/usr/bin/env bash
# Install selected agents and shared skills; preserve unrelated installations.
set -euo pipefail

usage() {
    echo 'Usage: scripts/install.sh [--project DIRECTORY] [--skill NAME ...] [--agent NAME ...] [--prefix PROJECT] [--target SKILLS_DIRECTORY] [--agents-target DIRECTORY] [--dry-run] [--force] [--list]'
}
fail() { echo "$*" >&2; exit 2; }

# Resolve existing symlinks and normalize missing path components without creating them.
canonical_dir() (
    local path="$1" parent leaf
    if [[ -d "$path" ]]; then
        cd -- "$path" && pwd -P
    else
        [[ ! -e "$path" && ! -L "$path" ]] || return 1
        parent="$(canonical_dir "$(dirname -- "$path")")" || return 1
        leaf="$(basename -- "$path")"
        case "$leaf" in
            .) echo "$parent" ;;
            ..) dirname -- "$parent" ;;
            *) echo "${parent%/}/$leaf" ;;
        esac
    fi
)

scripts_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_dir="$(cd -- "$scripts_dir/../skills" && pwd -P)"
target="${CODEX_HOME:-$HOME/.codex}/skills"
dry_run=false
force=false
selected=()
agent_selected=()
agent_target="${CODEX_HOME:-$HOME/.codex}/agents"
prefix=''
project=''
manual_selection=false
while (( $# )); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --force) force=true; shift ;;
        --project|--target|--skill|--agent|--agents-target|--prefix)
            (( $# >= 2 )) && [[ -n "$2" && "$2" != --* ]] || fail "$1 requires a value"
            if [[ "$1" != --project ]]; then manual_selection=true; fi
            case "$1" in
                --project) project="$2" ;;
                --target) target="$2" ;;
                --skill) selected+=("$2") ;;
                --agent) agent_selected+=("$2") ;;
                --agents-target) agent_target="$2" ;;
                --prefix) prefix="$2" ;;
            esac
            shift 2 ;;
        --list)
            echo 'Agents:'
            bash "$scripts_dir/install_agents.sh" --list
            echo 'Skills:'
            for path in "$source_dir"/*; do
                [[ -f "$path/SKILL.md" ]] && basename -- "$path"
            done
            exit 0 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; fail "Unknown argument: $1" ;;
    esac
done

# Project mode reads declarative data, never evaluates shell code or edits AGENTS.md.
if [[ -n "$project" ]]; then
    [[ "$manual_selection" == false ]] || fail '--project cannot be combined with manual selections, prefix, or target overrides'
    [[ -d "$project" ]] || fail 'Project directory does not exist'
    project="$(cd -- "$project" && pwd -P)"
    config="$project/.agent-workflow"
    [[ -f "$config" ]] || fail 'Missing .agent-workflow; copy templates/project.agent-workflow and select project roles first'
    [[ -f "$project/AGENTS.md" ]] || fail 'Project mode requires AGENTS.md to define its workflow'
    keys=()
    role_names=()
    role_agents=()
    required_roles=''
    stages=''
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" =~ ^([a-z][a-z0-9_.-]*)=([A-Za-z0-9_,./-]+)$ ]] || fail "Invalid project configuration line: $line"
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        for existing in ${keys[@]+"${keys[@]}"}; do
            [[ "$existing" != "$key" ]] || fail "Duplicate project configuration key: $key"
        done
        keys+=("$key")
        case "$key" in
            prefix) prefix="$value" ;;
            role.*)
                role="${key#role.}"
                [[ "$role" =~ ^[a-z][a-z0-9_]*$ && "$value" =~ ^[a-z][a-z0-9_]*$ ]] || fail "Invalid role mapping: $line"
                role_names+=("$role")
                role_agents+=("$value")
                if [[ "$value" != none ]]; then agent_selected+=("$value"); fi ;;
            required_roles) required_roles="$value" ;;
            stages) stages="$value" ;;
            max_repair_rounds) [[ "$value" =~ ^[1-9][0-9]*$ ]] || fail 'max_repair_rounds must be a positive integer' ;;
            base_branch|branch_policy|documentation|commit|publish_pr|merge) : ;;
            skill.*)
                [[ "$value" == enabled || "$value" == disabled ]] || fail "Invalid skill selection: $line"
                if [[ "$value" == enabled ]]; then selected+=("${key#skill.}"); fi ;;
            *) fail "Unknown project configuration key: $key" ;;
        esac
    done < "$config"
    [[ -n "$prefix" && "$prefix" =~ ^[a-z][a-z0-9_]*$ ]] || fail 'Project prefix is missing or invalid'
    [[ -n "$required_roles" && -n "$stages" ]] || fail 'Project requires required_roles and stages'
    IFS=',' read -r -a required <<< "$required_roles"
    for role in "${required[@]}"; do
        found=false
        for ((index=0; index<${#role_names[@]}; index++)); do
            if [[ "${role_names[$index]}" == "$role" && "${role_agents[$index]}" != none ]]; then found=true; fi
        done
        [[ "$found" == true ]] || fail "Required project role is unconfigured: $role"
    done
    IFS=',' read -r -a configured_stages <<< "$stages"
    for stage in "${configured_stages[@]}"; do
        needed_role=''
        case "$stage" in
            code) needed_role=coder ;;
            test) needed_role=tester ;;
            documentation) needed_role=documenter ;;
            commit|verify_ticket|publish_pr) : ;;
            *) fail "Unknown project workflow stage: $stage" ;;
        esac
        if [[ -n "$needed_role" ]]; then
            found=false
            for ((index=0; index<${#role_names[@]}; index++)); do
                if [[ "${role_names[$index]}" == "$needed_role" && "${role_agents[$index]}" != none ]]; then found=true; fi
            done
            [[ "$found" == true ]] || fail "Stage $stage requires a configured $needed_role role"
        fi
    done
    (( ${#agent_selected[@]} > 0 )) || fail 'Project selected no agents'
    target="$project/.agents/skills"
    agent_target="$project/.codex/agents"
    echo "Project workflow: $config"
fi

if [[ -n "$prefix" ]] && (( ${#agent_selected[@]} == 0 )); then
    fail '--prefix requires at least one --agent selection'
fi
for agent in ${agent_selected[@]+"${agent_selected[@]}"}; do
    case "$agent" in
        roadmap_design) selected+=(ticket-writing workflow-pr) ;;
        workflow_coordinator) selected+=(ticket-writing workflow-pr) ;;
        typescript_backend_coder) selected+=(ticket-writing workflow-pr) ;;
        backend_tester) selected+=(ticket-writing workflow-pr) ;;


        *) fail "Unknown agent: $agent" ;;
    esac
done
if (( ${#selected[@]} == 0 )); then
    for path in "$source_dir"/*; do
        [[ -d "$path" && -f "$path/SKILL.md" ]] || continue
        selected+=("$(basename -- "$path")")
    done
fi
(( ${#selected[@]} )) || fail 'No skills found'
# Expand dependencies before any destination writes. Indexed arrays support macOS Bash 3.2.
index=0
while (( index < ${#selected[@]} )); do
    name="${selected[$index]}"
    [[ "$name" != */* && -f "$source_dir/$name/SKILL.md" ]] || fail "Unknown skill: $name"
    dependencies=()
    case "$name" in
        workflow-pr) dependencies=(workflow-commit) ;;
        workflow-youtrack) dependencies=(ticket-writing) ;;

    esac
    for dependency in ${dependencies[@]+"${dependencies[@]}"}; do
        found=false
        for chosen in "${selected[@]}"; do
            if [[ "$chosen" == "$dependency" ]]; then found=true; break; fi
        done
        if [[ "$found" == false ]]; then selected+=("$dependency"); fi
    done
    index=$((index + 1))
done
# Deduplicate repeated selections and produce deterministic output.
ordered=()
while IFS= read -r name; do ordered+=("$name"); done < <(printf '%s\n' "${selected[@]}" | LC_ALL=C sort -u)
selected=("${ordered[@]}")
target="$(canonical_dir "$target")" || fail 'Target must resolve to a directory'
home_dir="$(cd -- "$HOME" && pwd -P)"
[[ "$target" != / && "$target" != "$home_dir" ]] || fail 'Refusing root or home as a skills directory'
case "$target/" in "$source_dir/"*) fail 'Target overlaps skill sources' ;; esac
case "$source_dir/" in "$target/"*) fail 'Target overlaps skill sources' ;; esac

actions=()
for name in "${selected[@]}"; do
    destination="$target/$name"
    [[ ! -L "$destination" ]] || fail "Refusing symlink destination: $destination"
    [[ ! -e "$destination" || -d "$destination" ]] || fail "Refusing non-directory destination: $destination"
    if [[ -d "$destination" ]] && diff -qr "$source_dir/$name" "$destination" >/dev/null; then
        actions+=(unchanged)
    elif [[ -e "$destination" ]]; then
        [[ "$force" == true ]] || fail "Differing installed skill: $destination. Review before using --force."
        actions+=(replace)
    else
        actions+=(install)
    fi
done

# Preflight both component types before either installer changes a destination.
agent_options=(--target "$agent_target")
if [[ -n "$prefix" ]]; then agent_options+=(--prefix "$prefix"); fi
if [[ "$force" == true ]]; then agent_options+=(--force); fi
for agent in ${agent_selected[@]+"${agent_selected[@]}"}; do
    agent_options+=(--agent "$agent")
done
if (( ${#agent_selected[@]} > 0 )); then
    bash "$scripts_dir/install_agents.sh" "${agent_options[@]}" --dry-run >/dev/null
fi

stage=''
destination=''
cleanup() {
    local result=$?
    if [[ -n "$stage" && -d "$stage" ]]; then
        if [[ -d "$stage/backup" && ! -e "$destination" ]]; then
            if ! mv -- "$stage/backup" "$destination"; then
                echo "Restore failed; previous skill preserved at $stage/backup" >&2
                exit 1
            fi
        fi
        rm -rf -- "$stage"
    fi
    if (( result != 0 )); then echo 'Installation failed; earlier reported installations may have completed.' >&2; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for ((index=0; index<${#selected[@]}; index++)); do
    name="${selected[$index]}"
    action="${actions[$index]}"
    destination="$target/$name"
    if [[ "$action" == unchanged ]]; then
        echo "unchanged $destination"
    elif [[ "$dry_run" == true ]]; then
        echo "would $action $destination"
    else
        mkdir -p -- "$target"
        stage="$(mktemp -d "$target/.agent-workflows.XXXXXX")"
        cp -R -- "$source_dir/$name" "$stage/skill"
        if [[ "$action" == replace ]]; then mv -- "$destination" "$stage/backup"; fi
        mv -- "$stage/skill" "$destination"
        rm -rf -- "$stage"
        stage=''
        echo "installed $destination"
    fi
done
if (( ${#agent_selected[@]} > 0 )); then
    if [[ "$dry_run" == true ]]; then agent_options+=(--dry-run); fi
    bash "$scripts_dir/install_agents.sh" "${agent_options[@]}"
fi
if [[ "$dry_run" == true ]]; then
    echo 'Dry run complete; no files written.'
else
    echo 'Skill installation complete.'
fi
