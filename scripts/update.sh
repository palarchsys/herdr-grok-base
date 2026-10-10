#!/usr/bin/env bash
# Pull the protocol root, refresh each project, then ask about readmes and push.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

if ! git -C "$root" remote get-url origin >/dev/null 2>&1; then
  echo "No origin."
  exit 1
fi

# projects/ holds nested checkouts. Their files are not the protocol tree.
protocol_dirty() {
  local line path
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    path="${line:3}"
    if [[ "$path" == *" -> "* ]]; then
      path="${path##* -> }"
    fi
    path="${path#\"}"
    path="${path%\"}"
    case "$path" in
      projects|projects/*) continue ;;
    esac
    return 0
  done < <(git -C "$root" status --porcelain)
  return 1
}

if protocol_dirty; then
  echo "Dirty tree."
  exit 1
fi
git -C "$root" pull --ff-only

append_ignore() {
  local file="$1" line
  local lines=(
    registry.sqlite
    registry.sqlite-journal
    registry.sqlite-wal
    registry.sqlite-shm
  )
  if [[ ! -f "$file" ]]; then
    printf '%s\n' "${lines[@]}" > "$file"
    return 0
  fi
  for line in "${lines[@]}"; do
    if grep -qxF "$line" "$file"; then
      continue
    fi
    if [[ -s "$file" ]]; then
      printf '\n%s\n' "$line" >> "$file"
    else
      printf '%s\n' "$line" >> "$file"
    fi
  done
}

overwrite_project() {
  local dest="$1" srcf base formats_existed=0
  mkdir -p "$dest/formats" "$dest/scripts"
  if [[ -f "$dest/AGENTS.md" ]]; then
    cp -f "$root/AGENTS.md" "$dest/AGENTS.md"
    echo "AGENTS.md updated"
  else
    cp "$root/AGENTS.md" "$dest/AGENTS.md"
    echo "AGENTS.md installed"
  fi
  shopt -s nullglob
  for srcf in "$root/formats"/*; do
    base="$(basename "$srcf")"
    if [[ -e "$dest/formats/$base" ]]; then
      formats_existed=1
    fi
    cp -f "$srcf" "$dest/formats/$base"
  done
  shopt -u nullglob
  if [[ "$formats_existed" -eq 1 ]]; then
    echo "formats updated"
  else
    echo "formats installed"
  fi
  if [[ -f "$dest/scripts/index-symbols.py" ]]; then
    cp -f "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"
    echo "index-symbols.py updated"
  else
    cp "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"
    echo "index-symbols.py installed"
  fi
  if [[ ! -f "$dest/registry.sqlite" ]]; then
    sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
    echo "database created"
  else
    sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
    echo "registry.sqlite kept, schema ensured"
  fi
  append_ignore "$dest/.gitignore"
}

shopt -s nullglob
for proj in "$root/projects"/*; do
  [[ -d "$proj" ]] || continue
  overwrite_project "$proj"
done
shopt -u nullglob

ask() {
  local prompt="$1" answer
  while true; do
    read -r -p "$prompt" answer || exit 1
    case "$answer" in
      Oui|oui|O|o) return 0 ;;
      Non|non|N|n) return 1 ;;
    esac
  done
}

if ask "Mise a jour des readmes ? Oui/Non : "; then
  shopt -s nullglob
  for proj in "$root/projects"/*; do
    [[ -d "$proj" ]] || continue
    cp -f "$root/README.md" "$proj/README.md"
  done
  shopt -u nullglob
fi

if ! ask "Commit et push vers le depot ? Oui/Non : "; then
  exit 0
fi

read -r -p "Commentaire : " comment || exit 1
if [[ -z "$comment" ]]; then
  echo "Empty comment."
  exit 1
fi

commit_repo() {
  local repo="$1"
  if [[ ! -e "$repo/.git" ]]; then
    return 0
  fi
  if [[ "$repo" == "$root" ]]; then
    if ! protocol_dirty; then
      return 0
    fi
    git -C "$repo" add -A -- . ':!projects'
  else
    if [[ -z "$(git -C "$repo" status --porcelain)" ]]; then
      return 0
    fi
    git -C "$repo" add -A
  fi
  git -C "$repo" commit -m "$comment"
  git -C "$repo" push
}

commit_repo "$root"
shopt -s nullglob
for proj in "$root/projects"/*; do
  [[ -d "$proj" ]] || continue
  commit_repo "$proj"
done
shopt -u nullglob
