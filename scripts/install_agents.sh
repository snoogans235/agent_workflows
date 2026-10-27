#!/usr/bin/env bash
# Install selected agent definitions with optional project-specific names.
set -euo pipefail
scripts_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_dir="$(cd -- "$scripts_dir/../agents" && pwd -P)"
target="${CODEX_HOME:-$HOME/.codex}/agents"
dry_run=false
force=false
prefix=''
selected=()
fail() { echo "$*" >&2; exit 2; }
usage() { echo 'Usage: scripts/install_agents.sh [--agent NAME ...] [--prefix PROJECT] [--dry-run] [--force] [--target DIRECTORY] [--list]'; }
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
while (( $# )); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --force) force=true; shift ;;
        --target|--agent|--prefix)
            (( $# >= 2 )) && [[ -n "$2" && "$2" != --* ]] || fail "$1 requires a value"
            case "$1" in
                --target) target="$2" ;;
                --agent) selected+=("$2") ;;
                --prefix) prefix="$2" ;;
            esac
            shift 2 ;;
        --list)
            for source in "$source_dir"/*.toml; do
                [[ -f "$source" ]] && basename -- "$source" .toml
            done
            exit 0 ;;
        --help|-h) usage; exit 0 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done
[[ -z "$prefix" || "$prefix" =~ ^[a-z][a-z0-9_]*$ ]] || fail 'Prefix must start with a lowercase letter and contain only lowercase letters, digits, or underscores'
if (( ${#selected[@]} == 0 )); then
    for source in "$source_dir"/*.toml; do
        [[ -f "$source" ]] && selected+=("$(basename -- "$source" .toml)")
    done
fi
(( ${#selected[@]} )) || fail 'No agent definitions found'
ordered=()
while IFS= read -r name; do ordered+=("$name"); done < <(printf '%s\n' "${selected[@]}" | LC_ALL=C sort -u)
selected=("${ordered[@]}")
target="$(canonical_dir "$target")" || fail 'Target must resolve to a directory'
home_dir="$(cd -- "$HOME" && pwd -P)"
[[ "$target" != / && "$target" != "$home_dir" ]] || fail 'Refusing root or home as an agents directory'
case "$target/" in "$source_dir/"*) fail 'Target overlaps agent sources' ;; esac
case "$source_dir/" in "$target/"*) fail 'Target overlaps agent sources' ;; esac

# Change only the top-level identity; keep the approved instructions intact.
render() {
    local source="$1" installed_name="$2"
    awk -v identity="$installed_name" '
        NR == 1 && /^name = / { print "name = \"" identity "\""; next }
        { print }
    ' "$source"
}
installed_names=()
for name in "${selected[@]}"; do
    [[ "$name" =~ ^[a-z][a-z0-9_]*$ && -f "$source_dir/$name.toml" ]] || fail "Unknown agent: $name"
    source="$source_dir/$name.toml"
    grep -Fqx "name = \"$name\"" "$source" || fail "Invalid agent identity: $source"
    grep -Eq '^description = ".+"$' "$source" || fail "Missing description: $source"
    grep -Fqx "developer_instructions = '''" "$source" || fail "Missing instructions: $source"
    [[ "$(tail -n 1 "$source")" == "'''" ]] || fail "Unclosed instructions: $source"
    installed_name="${prefix:+${prefix}_}$name"
    installed_names+=("$installed_name")
    destination="$target/$installed_name.toml"
    [[ ! -L "$destination" ]] || fail "Refusing symlink: $destination"
    [[ ! -e "$destination" || -f "$destination" ]] || fail "Refusing non-file: $destination"
    if [[ -e "$destination" ]] && ! cmp -s <(render "$source" "$installed_name") "$destination"; then
        [[ "$force" == true ]] || fail "Differing installed agent: $destination. Review before using --force."
    fi
done
stage=''
trap 'if [[ -n "$stage" ]]; then rm -f -- "$stage"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
for ((index=0; index<${#selected[@]}; index++)); do
    name="${selected[$index]}"
    installed_name="${installed_names[$index]}"
    source="$source_dir/$name.toml"
    destination="$target/$installed_name.toml"
    if [[ -f "$destination" ]] && cmp -s <(render "$source" "$installed_name") "$destination"; then
        echo "unchanged $destination"
    elif [[ "$dry_run" == true ]]; then
        echo "would install $destination"
    else
        mkdir -p -- "$target"
        stage="$(mktemp "$target/.agent-workflows.XXXXXX")"
        render "$source" "$installed_name" > "$stage"
        chmod 0644 "$stage"
        mv -f -- "$stage" "$destination"
        stage=''
        echo "installed $destination"
    fi
done
if [[ "$dry_run" == true ]]; then
    echo 'Dry run complete; no files written.'
else
    echo 'Agent installation complete.'
fi
