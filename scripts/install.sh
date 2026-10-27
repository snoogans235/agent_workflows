#!/usr/bin/env bash
# Install reusable skills without modifying unrelated skills or agent roles.
set -euo pipefail

usage() {
    echo 'Usage: scripts/install.sh [--dry-run] [--force] [--target DIRECTORY] [--skill NAME ...]'
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

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../skills" && pwd -P)"
target="${CODEX_HOME:-$HOME/.codex}/skills"
dry_run=false
force=false
selected=()
while (( $# )); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --force) force=true; shift ;;
        --target|--skill)
            (( $# >= 2 )) && [[ -n "$2" && "$2" != --* ]] || fail "$1 requires a value"
            if [[ "$1" == --target ]]; then target="$2"; else selected+=("$2"); fi
            shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; fail "Unknown argument: $1" ;;
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
if [[ "$dry_run" == true ]]; then
    echo 'Dry run complete; no files written.'
else
    echo 'Skill installation complete.'
fi
