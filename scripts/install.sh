#!/usr/bin/env bash
# Installation idempotente. N'écrit pas dans ~/.grok.
set -euo pipefail

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi
if [[ "${VERSION_ID:-}" != "26.04" ]]; then
  echo "Ubuntu 26.04 requis. Arrêt."
  exit 1
fi

step() { echo "== $1"; }

if command -v herdr >/dev/null 2>&1; then
  step "herdr déjà installé"
else
  step "install herdr"
  curl -fsSL https://herdr.dev/install.sh | sh
fi

if command -v grok >/dev/null 2>&1; then
  step "grok déjà installé"
else
  step "install grok"
  curl -fsSL https://x.ai/cli/install.sh | bash
fi

if command -v grok >/dev/null 2>&1 && grok inspect >/dev/null 2>&1; then
  step "grok déjà configuré, config laissée intacte"
else
  step "grok login"
  grok login
fi

if command -v herdr >/dev/null 2>&1; then
  if herdr integration list 2>/dev/null | grep -q grok; then
    step "intégration grok déjà présente"
  else
    step "intégration grok"
    herdr integration install grok
  fi
fi

missing=()
command -v sqlite3 >/dev/null 2>&1 || missing+=(sqlite3)
command -v rg >/dev/null 2>&1 || missing+=(ripgrep)
command -v curl >/dev/null 2>&1 || missing+=(curl)
command -v unzip >/dev/null 2>&1 || missing+=(unzip)
if ((
${#missing[@]})); then
  step "apt ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
else
  step "sqlite3 rg curl unzip déjà installés"
fi

if command -v ast-grep >/dev/null 2>&1; then
  step "ast-grep déjà installé"
else
  step "install ast-grep"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/ast-grep.zip" https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-gnu.zip
  sudo unzip -q -o "$tmp/ast-grep.zip" -d /usr/local/bin
  sudo ln -sfn /usr/local/bin/sg /usr/local/bin/ast-grep
  rm -rf "$tmp"
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/projets"

step "vérification"
sqlite3 --version
rg --version
ast-grep --version
herdr --version || true
grok --version || true
echo "Install terminée. Config Grok non écrasée."
