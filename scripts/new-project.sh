#!/usr/bin/env bash
# Create or adopt a project. Never overwrite an existing file. Never move source.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bashrc="${HOME}/.bashrc"
module_re='^[a-z][a-z0-9-]{0,24}$'
skip='^(requests|configs|agents|modules|formats|rules|scripts|\.git)(/|$)'

missing=()
command -v git >/dev/null 2>&1 || missing+=(git)
command -v sqlite3 >/dev/null 2>&1 || missing+=(sqlite3)
command -v rg >/dev/null 2>&1 || missing+=(rg)
command -v python3 >/dev/null 2>&1 || missing+=(python3)
if ((${#missing[@]})); then
  echo "Missing: ${missing[*]}. Run scripts/install.sh first."
  exit 1
fi

read -r -p "Project name [a-z0-9-] : " name
if [[ ! "$name" =~ $module_re ]]; then
  echo "Invalid name."
  exit 1
fi

read -r -p "Existing directory (empty = projects/$name) : " given
if [[ -n "$given" ]]; then
  if [[ ! -d "$given" ]]; then
    echo "Directory not found: $given"
    exit 1
  fi
  dest="$(cd "$given" && pwd)"
else
  dest="$root/projects/$name"
fi

if [[ "$dest" == "$root" ]]; then
  echo "Refusing the protocol repository."
  exit 1
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

copied=0
kept=0
shopt -s nullglob
for srcf in "$root/formats"/*; do
  base="$(basename "$srcf")"
  if [[ -e "$dest/formats/$base" ]]; then
    kept=1
  else
    cp -R "$srcf" "$dest/formats/$base"
    copied=1
  fi
done
shopt -u nullglob
if [[ "$copied" -eq 0 && "$kept" -eq 1 ]]; then
  echo "formats/ kept"
elif [[ "$copied" -eq 1 && "$kept" -eq 1 ]]; then
  echo "formats/ missing files copied"
fi

if [[ ! -f "$dest/registry.sqlite" ]]; then
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "database created"
else
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "registry.sqlite kept, schema ensured"
fi

if [[ ! -f "$dest/.gitignore" ]]; then
  cat > "$dest/.gitignore" << 'EOF'
registry.sqlite
registry.sqlite-journal
registry.sqlite-wal
registry.sqlite-shm
EOF
fi

if [[ ! -d "$dest/.git" ]]; then
  git -C "$dest" init -b main
else
  echo "git kept"
fi

add_glob() {
  local module="$1" glob="$2" cur line
  cur="${mod_globs[$module]:-}"
  if [[ -n "$cur" ]]; then
    while IFS= read -r line; do
      [[ "$line" == "$glob" ]] && return 0
    done <<< "$cur"
    mod_globs[$module]="${cur}"$'\n'"${glob}"
  else
    mod_globs[$module]="$glob"
  fi
}

classify() {
  local rel="$1" top second
  if [[ "$rel" == src/*/* ]]; then
    second="${rel#src/}"
    second="${second%%/*}"
    if [[ "$second" =~ $module_re ]]; then
      module="$second"
      glob="src/${second}/**"
      return 0
    fi
    module="core"
    glob="src/${second}/**"
    return 0
  fi
  if [[ "$rel" == src/* ]]; then
    module="core"
    glob="$rel"
    return 0
  fi
  if [[ "$rel" == */* ]]; then
    top="${rel%%/*}"
    if [[ "$top" =~ $module_re ]]; then
      module="$top"
      glob="${top}/**"
      return 0
    fi
    module="core"
    glob="${top}/**"
    return 0
  fi
  module="core"
  glob="$rel"
}

mkdir -p "$dest/scripts"
if [[ ! -f "$dest/scripts/index-symbols.py" ]]; then
  cp "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"
else
  echo "scripts/index-symbols.py kept"
fi

if [[ "$adopt" -eq 1 ]]; then
  echo "Indexing existing files. Source is not moved."
  declare -A mod_globs=()
  list="$(mktemp)"
  rg_rc=0
  (cd "$dest" && rg --files --hidden --glob '!.git/**' --glob '!registry.sqlite*' \
    --glob '!**/.git/**' --glob '!**/node_modules/**' --glob '!**/dist/**' \
    --glob '!**/target/**' --glob '!**/.venv/**' --glob '!**/venv/**' \
    --glob '!**/__pycache__/**' >"$list") || rg_rc=$?
  if [[ "$rg_rc" -gt 1 ]]; then
    rm -f "$list"
    echo "rg failed."
    exit 1
  fi
  rel=""
  sqlf="$(mktemp)"
  printf 'BEGIN;\n' >"$sqlf"
  while IFS= read -r rel || [[ -n "${rel}" ]]; do
    [[ -n "$rel" ]] || continue
    rel="${rel#./}"
    [[ "$rel" =~ $skip ]] && continue
    [[ "$rel" == "AGENTS.md" || "$rel" == "registry.sqlite" ]] && continue
    [[ "$rel" =~ (^|/)(node_modules|dist|target|\.venv|venv|__pycache__)(/|$) ]] && continue
    classify "$rel"
    sql_rel="${rel//\'/\'\'}"
    sql_mod="${module//\'/\'\'}"
    printf "INSERT OR IGNORE INTO files(path, module, summary) VALUES ('%s', '%s', '');\n" \
      "$sql_rel" "$sql_mod" >>"$sqlf"
    add_glob "$module" "$glob"
  done < "$list"
  rm -f "$list"
  printf 'COMMIT;\n' >>"$sqlf"
  sqlite3 "$dest/registry.sqlite" <"$sqlf"
  rm -f "$sqlf"
  if [[ "${#mod_globs[@]}" -gt 0 ]]; then
    for module in "${!mod_globs[@]}"; do
      moddir="$dest/modules/$module"
      mkdir -p "$moddir"
      if [[ -f "$moddir/MODULE.md" ]]; then
        continue
      fi
      {
        printf 'id: %s\n' "$module"
        printf 'owns:\n'
        while IFS= read -r glob; do
          [[ -n "$glob" ]] || continue
          printf '  - %s\n' "$glob"
        done < <(printf '%s\n' "${mod_globs[$module]}" | sed '/^$/d' | sort -u)
        printf '  - modules/%s/PLAN.md\n' "$module"
        cat << 'EOF'
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
      } > "$moddir/MODULE.md"
    done
  fi
  if [[ ! -f "$dest/requests/r-adopt-0.md" ]]; then
    body_text='Adopted existing tree. Files indexed. Source not moved.'
    adopt_hash="$(printf '%s' "$body_text" | sha256sum | cut -c1-12)"
    cat > "$dest/requests/r-adopt-0.md" << EOF
id: r-adopt-0
parent:
depth: 0
hash: $adopt_hash
origin: user
module:
config:
status: done
pointer:
body: |
  $body_text
EOF
    sqlite3 "$dest/registry.sqlite" \
      "INSERT OR IGNORE INTO requests(hash, id, parent, depth, module, config, status) VALUES ('$adopt_hash', 'r-adopt-0', '', 0, '', '', 'done');"
  fi
  if [[ "${#mod_globs[@]}" -gt 0 ]]; then
    for module in "${!mod_globs[@]}"; do
      (cd "$dest" && python3 scripts/index-symbols.py "$module")
    done
  fi
  echo "Adopted. Modules written only where missing."
fi

begin="# herdr-grok-base:${name}"
end="# herdr-grok-base:${name}:end"
dest_q="$(printf '%q' "$dest")"
touch "$bashrc"
if grep -qF "$begin" "$bashrc" && grep -qF "cd ${dest_q} " "$bashrc"; then
  echo "command $fn already in bashrc"
else
  existed=0
  if grep -qF "$begin" "$bashrc"; then
    existed=1
  fi
  block_file="$(mktemp)"
  {
    printf '%s\n' "$begin"
    printf '%s() {\n' "$fn"
    printf '  cd %s || return 1\n' "$dest_q"
    printf '  exec herdr\n'
    printf '}\n'
    printf '%s\n' "$end"
  } > "$block_file"
  tmp_bashrc="$(mktemp)"
  has_end=0
  if grep -qF "$end" "$bashrc"; then
    has_end=1
  fi
  awk -v begin="$begin" -v end="$end" -v blockfile="$block_file" -v has_end="$has_end" '
    function emit() {
      while ((getline line < blockfile) > 0) print line
      close(blockfile)
    }
    $0 == begin && !skipping {
      seen = 1
      emit()
      skipping = 1
      next
    }
    skipping {
      if (has_end == "1") {
        if ($0 == end) skipping = 0
      } else if ($0 ~ /^}$/) {
        skipping = 0
      }
      next
    }
    $0 == end && seen { next }
    { print }
    END {
      if (!seen) {
        print ""
        emit()
      }
    }
  ' "$bashrc" > "$tmp_bashrc"
  cat "$tmp_bashrc" > "$bashrc"
  rm -f "$tmp_bashrc" "$block_file"
  if [[ "$existed" -eq 1 ]]; then
    echo "command $fn updated"
  else
    echo "command $fn added"
  fi
fi

echo
echo "Launch:"
echo "  source ~/.bashrc && $fn"
echo "Directory: $dest"
