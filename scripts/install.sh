#!/usr/bin/env bash
# Idempotent install. Does not modify existing Grok config.
# The Herdr hook is added only when missing (~/.grok/hooks/, not config.toml).
set -euo pipefail

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
fi
if [[ "${VERSION_ID:-}" != "26.04" ]]; then
  echo "Ubuntu 26.04 required. Stop."
  exit 1
fi

export PATH="${HOME}/.local/bin:${HOME}/.grok/bin:/usr/local/bin:${PATH}"

step() { echo "== $1"; }

have_root() {
  if sudo -n true >/dev/null 2>&1; then
    return 0
  fi
  [[ -t 0 ]]
}

place_bin() {
  local src="$1" name="$2"
  if have_root; then
    sudo install -m 0755 "$src" "/usr/local/bin/${name}"
  else
    mkdir -p "${HOME}/.local/bin"
    install -m 0755 "$src" "${HOME}/.local/bin/${name}"
  fi
}

install_user_sqlite() {
  local tmp file year url src
  tmp="$(mktemp -d)"
  file="$(curl -fsSL https://sqlite.org/download.html | grep -o 'sqlite-tools-linux-x64-[0-9]*\.zip' | head -n 1)"
  if [[ -z "$file" ]]; then
    echo "sqlite.org did not list a linux x64 tools archive."
    exit 1
  fi
  year="$(date +%Y)"
  url="https://sqlite.org/${year}/${file}"
  if ! curl -fsI "$url" >/dev/null 2>&1; then
    url="https://sqlite.org/$((year - 1))/${file}"
  fi
  curl -fsSL -o "$tmp/sqlite.zip" "$url"
  unzip -q -o "$tmp/sqlite.zip" -d "$tmp"
  src="$(find "$tmp" -type f -name sqlite3 -print -quit)"
  if [[ -z "$src" ]]; then
    echo "Archive has no sqlite3 binary."
    exit 1
  fi
  place_bin "$src" sqlite3
  rm -rf "$tmp"
}

install_user_rg() {
  local tmp triple url src
  case "$(uname -m)" in
    x86_64|amd64) triple="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) triple="aarch64-unknown-linux-musl" ;;
    *)
      echo "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac
  tmp="$(mktemp -d)"
  url="$(curl -fsSL -H 'User-Agent: herdr-grok-base' \
    https://api.github.com/repos/BurntSushi/ripgrep/releases/latest \
    | grep -o "https://github.com/BurntSushi/ripgrep/releases/download/[^\"]*${triple}\\.tar\\.gz" \
    | head -n 1)"
  if [[ -z "$url" ]]; then
    echo "ripgrep release has no ${triple} archive."
    exit 1
  fi
  curl -fsSL -o "$tmp/rg.tar.gz" "$url"
  tar -xzf "$tmp/rg.tar.gz" -C "$tmp"
  src="$(find "$tmp" -type f -name rg -print -quit)"
  if [[ -z "$src" ]]; then
    echo "Archive has no rg binary."
    exit 1
  fi
  place_bin "$src" rg
  rm -rf "$tmp"
}

missing=()
command -v curl >/dev/null 2>&1 || missing+=(curl)
command -v unzip >/dev/null 2>&1 || missing+=(unzip)
command -v sqlite3 >/dev/null 2>&1 || missing+=(sqlite3)
command -v rg >/dev/null 2>&1 || missing+=(ripgrep)
if [[ ! -s /etc/ssl/certs/ca-certificates.crt ]]; then
  missing+=(ca-certificates)
fi
if ((${#missing[@]})); then
  if have_root; then
    step "apt ${missing[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
  else
    step "no root, user-local ${missing[*]}"
    for item in "${missing[@]}"; do
      case "$item" in
        sqlite3) install_user_sqlite ;;
        ripgrep) install_user_rg ;;
        *)
          echo "Need root to install ${item}."
          exit 1
          ;;
      esac
    done
  fi
else
  step "curl unzip sqlite3 rg ca-certificates already installed"
fi

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

if command -v grok >/dev/null 2>&1; then
  if [[ -n "${GROK_DEPLOYMENT_KEY:-}" || -s "${HOME}/.grok/auth.json" ]]; then
    step "grok already configured, config left intact"
  else
    step "grok login"
    grok login
  fi
fi

if command -v herdr >/dev/null 2>&1; then
  state="$(herdr integration status | awk '/^grok:/ { print $2 }')"
  if [[ "$state" == "current" ]]; then
    step "grok integration already present"
  else
    step "grok integration"
    herdr integration install grok
  fi
fi

if ast-grep --version >/dev/null 2>&1; then
  step "ast-grep already installed"
else
  step "install ast-grep"
  case "$(uname -m)" in
    x86_64|amd64) asset="app-x86_64-unknown-linux-gnu.zip" ;;
    aarch64|arm64) asset="app-aarch64-unknown-linux-gnu.zip" ;;
    *)
      echo "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/ast-grep.zip" \
    "https://github.com/ast-grep/ast-grep/releases/latest/download/${asset}"
  unzip -q -o "$tmp/ast-grep.zip" ast-grep -d "$tmp"
  if [[ ! -s "$tmp/ast-grep" ]]; then
    echo "Archive has no ast-grep binary."
    exit 1
  fi
  place_bin "$tmp/ast-grep" ast-grep
  rm -rf "$tmp"
  trap - EXIT
fi

step "check"
sqlite3 --version
rg --version
ast-grep --version
herdr --version
grok --version
echo "Install done. Grok config not overwritten."
