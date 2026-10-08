#!/usr/bin/env bash
# Idempotent install. Does not write to ~/.grok.
set -euo pipefail

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi
if [[ "${VERSION_ID:-}" != "26.04" ]]; then
  echo "Ubuntu 26.04 required. Stop."
  exit 1
fi

step() { echo "== $1"; }

if command -v herdr >/dev/null 2>&1; then
  step "herdr already installed"
else
  step "install herdr"
  curl -fsSL https://herdr.dev/install.sh | sh
fi

if command -v grok >/dev/null 2>&1; then
  step "grok already installed"
else
  step "install grok"
  curl -fsSL https://x.ai/cli/install.sh | bash
fi

if command -v grok >/dev/null 2>&1 && grok inspect >/dev/null 2>&1; then
  step "grok already configured, config left intact"
else
  step "grok login"
  grok login
fi

if command -v herdr >/dev/null 2>&1; then
  if herdr integration list 2>/dev/null | grep -q grok; then
    step "grok integration already present"
  else
    step "grok integration"
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
  step "sqlite3 rg curl unzip already installed"
fi

if command -v ast-grep >/dev/null 2>&1; then
  step "ast-grep already installed"
else
  step "install ast-grep"
  tmp="$(mktemp -d)"
  wget -qO "$tmp/ast-grep.zip" https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-gnu.zip
  sudo unzip -q -o "$tmp/ast-grep.zip" -d /usr/local/bin
  sudo ln -sfn /usr/local/bin/sg /usr/local/bin/ast-grep
  rm -rf "$tmp"
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/projects"

step "check"
sqlite3 --version
rg --version
ast-grep --version
herdr --version || true
grok --version || true
echo "Install done. Grok config not overwritten."
