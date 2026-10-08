#!/usr/bin/env bash
# Create a project. Do not overwrite an existing file.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bashrc="${HOME}/.bashrc"
touch "$bashrc"

read -r -p "Project name [a-z0-9-] : " name
if [[ ! "$name" =~ ^[a-z][a-z0-9-]{0,24}$ ]]; then
  echo "Invalid name."
  exit 1
fi

dest="$root/projects/$name"
fn="herdr-$name"

if [[ -d "$dest" ]]; then
  echo "Project already present: $dest"
else
  echo "Creating: $dest"
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
  echo "registry.sqlite kept"
fi

if [[ ! -d "$dest/.git" ]]; then
  git -C "$dest" init
else
  echo "git kept"
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
