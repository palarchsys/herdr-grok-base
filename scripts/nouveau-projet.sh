#!/usr/bin/env bash
# Crée un projet. N'écrase pas un fichier déjà présent.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bashrc="${HOME}/.bashrc"
touch "$bashrc"

read -r -p "Nom du projet [a-z0-9-] : " nom
if [[ ! "$nom" =~ ^[a-z][a-z0-9-]{0,24}$ ]]; then
  echo "Nom invalide."
  exit 1
fi

dest="$root/projets/$nom"
fn="herdr-$nom"

if [[ -d "$dest" ]]; then
  echo "Projet déjà présent : $dest"
else
  echo "Création : $dest"
fi

mkdir -p "$dest"/{demandes,configs/sources,agents/clos,modules,src,formats,regles}

if [[ ! -f "$dest/AGENTS.md" ]]; then
  cp "$root/AGENTS.md" "$dest/AGENTS.md"
else
  echo "AGENTS.md conservé"
fi

if [[ ! -d "$dest/formats" || -z "$(ls -A "$dest/formats" 2>/dev/null || true)" ]]; then
  cp -R "$root/formats/." "$dest/formats/"
else
  echo "formats/ conservé"
fi

if [[ ! -f "$dest/registre.sqlite" ]]; then
  sqlite3 "$dest/registre.sqlite" < "$root/formats/registre.sql"
  echo "base créée"
else
  echo "registre.sqlite conservé"
fi

if [[ ! -d "$dest/.git" ]]; then
  git -C "$dest" init
else
  echo "git conservé"
fi

marker="# herdr-grok-base:$nom"
if grep -qF "$marker" "$bashrc"; then
  echo "commande $fn déjà dans bashrc"
else
  cat >> "$bashrc" << EOF

$marker
$fn() {
  cd "$dest" || return 1
  exec herdr
}
EOF
  echo "commande $fn ajoutée"
fi

# shellcheck disable=SC1090
source "$bashrc"

echo
echo "Lancer :"
echo "  source ~/.bashrc && $fn"
echo "Dossier : $dest"
