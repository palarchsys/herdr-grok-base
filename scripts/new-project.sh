#!/usr/bin/env bash
# Create or adopt a project. Never overwrite an existing file. Never move source.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bashrc="${HOME}/.bashrc"
touch "$bashrc"

read -r -p "Project name [a-z0-9-] : " name
if [[ ! "$name" =~ ^[a-z][a-z0-9-]{0,24}$ ]]; then
  echo "Invalid name."
  exit 1
fi

read -r -p "Existing directory (empty = projects/$name) : " given
if [[ -n "$given" ]]; then
  dest="$(cd "$given" && pwd)"
else
  dest="$root/projects/$name"
fi

fn="herdr-$name"
adopt=0
if [[ -d "$dest" ]]; then
  echo "Existing project: $dest"
  adopt=1
else
  echo "Creating: $dest"
  mkdir -p "$dest"
fi

mkdir -p "$dest"/{requests,configs/sources,agents/closed,modules,src,formats,rules}

if [[ ! -f "$dest/AGENTS.md" ]]; then
  cp "$root/AGENTS.md" "$dest/AGENTS.md"
else
  echo "AGENTS.md kept"
fi

if [[ ! -d "$dest/formats" || -z "$(ls -A "$dest/formats" 2>/dev/null || true)" ]]; then
  cp -R "$root/formats/." "$dest/formats/"
else
  echo "formats/ kept"
fi

if [[ ! -f "$dest/registry.sqlite" ]]; then
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "database created"
else
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "registry.sqlite kept, schema ensured"
fi

if [[ ! -d "$dest/.git" ]]; then
  git -C "$dest" init
else
  echo "git kept"
fi

if [[ "$adopt" -eq 1 ]]; then
  echo "Indexing existing files. Source is not moved."
  skip='^(requests|configs|agents|modules|formats|rules|\.git)(/|$)'
  while IFS= read -r path; do
    rel="${path#./}"
    [[ "$rel" =~ $skip ]] && continue
    [[ "$rel" == "AGENTS.md" || "$rel" == "registry.sqlite" ]] && continue
    module="$(printf '%s' "$rel" | cut -d/ -f1)"
    [[ "$module" == "src" ]] && module="$(printf '%s' "$rel" | cut -d/ -f2)"
    [[ "$module" =~ ^[a-z][a-z0-9-]{0,24}$ ]] || module="core"
    sql_rel="${rel//\'/\'\'}"
    sql_mod="${module//\'/\'\'}"
    sqlite3 "$dest/registry.sqlite" \
      "INSERT OR IGNORE INTO files(path, module, summary) VALUES ('$sql_rel', '$sql_mod', 'adopted');"
    moddir="$dest/modules/$module"
    mkdir -p "$moddir"
    if [[ ! -f "$moddir/MODULE.md" ]]; then
      owns="$module/**"
      [[ "$rel" == src/* ]] && owns="src/$module/**"
      cat > "$moddir/MODULE.md" << EOF
id: $module
owns:
  - $owns
  - modules/$module/PLAN.md
exports: []
imports: []
events_in: []
events_out: []
forbidden:
  - write outside owns
  - read requests configs agents locks rules
  - call an agent
  - open a tab
EOF
    fi
  done < <(cd "$dest" && rg --files --hidden --glob '!.git/**' --glob '!registry.sqlite*' --sortr modified)
  if [[ ! -f "$dest/requests/r-adopt-0.md" ]]; then
    cat > "$dest/requests/r-adopt-0.md" << EOF
id: r-adopt-0
parent:
depth: 0
hash: adopt
origin: user
module:
config:
status: done
pointer:
body: |
  Adopted existing tree. Files indexed. Source not moved.
EOF
    sqlite3 "$dest/registry.sqlite" \
      "INSERT OR IGNORE INTO requests(hash, id, parent, depth, module, config, status) VALUES ('adopt', 'r-adopt-0', '', 0, '', '', 'done');"
  fi
  echo "Adopted. Modules written only where missing."
fi

marker="# herdr-grok-base:$name"
if grep -qF "$marker" "$bashrc"; then
  echo "command $fn already in bashrc"
else
  cat >> "$bashrc" << EOF

$marker
$fn() {
  cd "$dest" || return 1
  exec herdr
}
EOF
  echo "command $fn added"
fi

# shellcheck disable=SC1090
source "$bashrc"

echo
echo "Launch:"
echo "  source ~/.bashrc && $fn"
echo "Directory: $dest"
