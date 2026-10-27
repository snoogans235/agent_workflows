#!/usr/bin/env bash
# Install agent definitions; shared skills use install.sh.
set -euo pipefail
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../agents" && pwd -P)"
target="${CODEX_HOME:-$HOME/.codex}/agents"
dry_run=false
force=false
fail() { echo "$*" >&2; exit 2; }
while (( $# )); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --force) force=true; shift ;;
        --target)
            (( $# >= 2 )) && [[ -n "$2" && "$2" != --* ]] || fail '--target requires a directory'
            target="$2"; shift 2 ;;
        --help|-h) echo 'Usage: scripts/install_agents.sh [--dry-run] [--force] [--target DIRECTORY]'; exit 0 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done
[[ -n "$target" ]] || fail 'Empty target'
[[ ! -e "$target" || -d "$target" ]] || fail 'Target must be a directory'
# A nonexistent directory is created only during installation, never during preview.
shopt -s nullglob
sources=("$source_dir"/*.toml)
(( ${#sources[@]} )) || fail 'No agent definitions found'
for source in "${sources[@]}"; do
    name="$(basename -- "$source" .toml)"
    grep -Fqx "name = \"$name\"" "$source" || fail "Invalid agent identity: $source"
    grep -Eq '^description = ".+"$' "$source" || fail "Missing description: $source"
    grep -Fqx "developer_instructions = '''" "$source" || fail "Missing instructions: $source"
    [[ "$(tail -n 1 "$source")" == "'''" ]] || fail "Unclosed instructions: $source"
    destination="$target/$name.toml"
    [[ ! -L "$destination" ]] || fail "Refusing symlink: $destination"
    [[ ! -e "$destination" || -f "$destination" ]] || fail "Refusing non-file: $destination"
    if [[ -e "$destination" ]] && ! cmp -s "$source" "$destination"; then
        [[ "$force" == true ]] || fail "Differing installed agent: $destination. Review before using --force."
    fi
done
stage=''
trap 'if [[ -n "$stage" ]]; then rm -f -- "$stage"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for source in "${sources[@]}"; do
    destination="$target/$(basename -- "$source")"
    if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
        echo "unchanged $destination"
    elif [[ "$dry_run" == true ]]; then
        echo "would install $destination"
    else
        mkdir -p -- "$target"
        stage="$(mktemp "$target/.agent-workflows.XXXXXX")"
        cp -- "$source" "$stage"
        chmod 0644 "$stage"
        mv -f -- "$stage" "$destination"
        stage=''
        echo "installed $destination"
    fi
done
if [[ "$dry_run" == true ]]; then
    echo 'Dry run complete; no files written.'
else
    echo 'Agent installation complete. Install the shared skills separately with scripts/install.sh.'
fi
