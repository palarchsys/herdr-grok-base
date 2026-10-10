#!/usr/bin/env bash
# Pull the protocol root, then report each project as updated or current.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

if ! git -C "$root" remote get-url origin >/dev/null 2>&1; then
  echo "No origin."
  exit 1
fi

# projects/ holds nested checkouts. Their files are not the protocol tree.
porcelain_path() {
  local path="${1:3}"
  if [[ "$path" == *" -> "* ]]; then
    path="${path##* -> }"
  fi
  path="${path#\"}"
  path="${path%\"}"
  printf '%s\n' "$path"
}

protocol_dirty_paths() {
  local line path
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    path="$(porcelain_path "$line")"
    case "$path" in
      projects|projects/*) continue ;;
      .Trash-1000|.Trash-1000/*) continue ;;
      .idea|.idea/*) continue ;;
    esac
    printf '%s\n' "$path"
  done < <(git -C "$root" status --porcelain)
}

protocol_dirty() {
  [[ -n "$(protocol_dirty_paths)" ]]
}

if ! branch="$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)" || [[ -z "$branch" ]]; then
  echo "Detached head."
  exit 1
fi

if ! pull_out="$(git -C "$root" pull --ff-only origin "$branch" 2>&1)"; then
  if protocol_dirty; then
    echo "Dirty tree."
    protocol_dirty_paths
    exit 1
  fi
  if [[ -n "$pull_out" ]]; then
    printf '%s\n' "$pull_out"
  fi
  exit 1
fi
if [[ -n "$pull_out" ]]; then
  printf '%s\n' "$pull_out"
fi

append_ignore() {
  local file="$1" line wrote=0
  local lines=(
    registry.sqlite
    registry.sqlite-journal
    registry.sqlite-wal
    registry.sqlite-shm
  )
  if [[ ! -f "$file" ]]; then
    printf '%s\n' "${lines[@]}" > "$file" || exit 1
    return 0
  fi
  for line in "${lines[@]}"; do
    if grep -qxF "$line" "$file"; then
      continue
    fi
    if [[ -s "$file" ]]; then
      printf '\n%s\n' "$line" >> "$file" || exit 1
    else
      printf '%s\n' "$line" >> "$file" || exit 1
    fi
    wrote=1
  done
  [[ "$wrote" -eq 1 ]]
}

copy_if_changed() {
  local from="$1" to="$2"
  if [[ -f "$to" ]] && cmp -s "$from" "$to"; then
    return 1
  fi
  cp -f "$from" "$to" || exit 1
}

refresh_project() {
  local dest="$1" name srcf base
  local -a changed=() bases=()
  name="$(basename "$dest")"
  mkdir -p "$dest/formats" "$dest/scripts"
  if copy_if_changed "$root/AGENTS.md" "$dest/AGENTS.md"; then
    changed+=(AGENTS.md)
  fi
  shopt -s nullglob
  for srcf in "$root/formats"/*; do
    [[ -f "$srcf" ]] || continue
    bases+=("$(basename "$srcf")")
  done
  shopt -u nullglob
  if ((${#bases[@]})); then
    while IFS= read -r base; do
      [[ -n "$base" ]] || continue
      if copy_if_changed "$root/formats/$base" "$dest/formats/$base"; then
        changed+=("formats/$base")
      fi
    done < <(printf '%s\n' "${bases[@]}" | LC_ALL=C sort)
  fi
  if copy_if_changed "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"; then
    changed+=(scripts/index-symbols.py)
  fi
  if append_ignore "$dest/.gitignore"; then
    changed+=(".gitignore")
  fi
  if [[ ! -f "$dest/registry.sqlite" ]]; then
    sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
    changed+=(registry.sqlite)
  else
    sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  fi
  if ((${#changed[@]})); then
    printf '%s: updated\n' "$name"
    printf '  %s\n' "${changed[@]}"
  else
    printf '%s: current\n' "$name"
  fi
}

shopt -s nullglob
for proj in "$root/projects"/*; do
  [[ -d "$proj" ]] || continue
  refresh_project "$proj"
done
shopt -u nullglob
