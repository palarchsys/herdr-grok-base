#!/usr/bin/env bash
# Create or adopt a project. Overwrite protocol files. Move other root entries into src/.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
module_re='^[a-z][a-z0-9-]{0,24}$'
skip='^(requests|configs|agents|modules|formats|rules|scripts|\.git)(/|$)'

missing=()
command -v git >/dev/null 2>&1 || missing+=(git)
command -v sqlite3 >/dev/null 2>&1 || missing+=(sqlite3)
command -v rg >/dev/null 2>&1 || missing+=(rg)
command -v python3 >/dev/null 2>&1 || missing+=(python3)
command -v gh >/dev/null 2>&1 || missing+=(gh)
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

login="$(gh api user --jq .login)" || exit 1
if [[ -z "$login" ]]; then
  exit 1
fi

if view_out="$(gh repo view "$login/$name" --json name 2>&1)"; then
  repo_exists=1
elif [[ "$view_out" == *"Could not resolve"* ]]; then
  repo_exists=0
else
  exit 1
fi

adopt=0
existed=0
if [[ -d "$dest" ]]; then
  echo "Existing project: $dest"
  adopt=1
  existed=1
else
  echo "Creating: $dest"
  mkdir -p "$root/projects"
  if [[ "$repo_exists" -eq 1 ]]; then
    gh repo clone "$login/$name" "$dest"
    adopt=1
  else
    (cd "$root/projects" && gh repo create "$name" --private --clone)
  fi
fi

mkdir -p "$dest"/{requests,configs/sources,agents/closed,modules,src,formats,rules,scripts}

if [[ -f "$dest/AGENTS.md" ]]; then
  cp "$root/AGENTS.md" "$dest/AGENTS.md"
  echo "AGENTS.md updated"
else
  cp "$root/AGENTS.md" "$dest/AGENTS.md"
  echo "AGENTS.md installed"
fi

formats_existed=0
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

if [[ ! -f "$dest/registry.sqlite" ]]; then
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "database created"
else
  sqlite3 "$dest/registry.sqlite" < "$root/formats/registry.sql"
  echo "registry.sqlite kept, schema ensured"
fi

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

append_ignore "$dest/.gitignore"

if [[ ! -d "$dest/.git" ]]; then
  git -C "$dest" init -b main
else
  echo "git kept"
fi

if [[ "$existed" -eq 1 ]]; then
  origin_exists=0
  if git -C "$dest" remote get-url origin >/dev/null 2>&1; then
    origin_exists=1
  fi
  if [[ "$repo_exists" -eq 0 ]]; then
    if [[ "$origin_exists" -eq 0 ]]; then
      gh repo create "$name" --private --source "$dest" --remote origin
    else
      gh repo create "$name" --private --source "$dest"
    fi
  elif [[ "$origin_exists" -eq 0 ]]; then
    url="$(gh repo view "$login/$name" --json url --jq .url)" || exit 1
    if [[ -z "$url" ]]; then
      exit 1
    fi
    git -C "$dest" remote add origin "${url}.git"
  fi
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

if [[ -f "$dest/scripts/index-symbols.py" ]]; then
  cp -f "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"
  echo "index-symbols.py updated"
else
  cp "$root/scripts/index-symbols.py" "$dest/scripts/index-symbols.py"
  echo "index-symbols.py installed"
fi

is_tracked() {
  git -C "$dest" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

move_entry() {
  local from_rel="$1" to_rel="$2" name="$3"
  if [[ -e "$dest/$to_rel" ]]; then
    echo "left in place: $name"
    return 0
  fi
  mkdir -p "$(dirname "$dest/$to_rel")"
  if is_tracked "$from_rel"; then
    git -C "$dest" mv -- "$from_rel" "$to_rel"
  else
    mv -- "$dest/$from_rel" "$dest/$to_rel"
  fi
}

move_foreign() {
  local entry name dotglob_was=0 nullglob_was=0
  shopt -q dotglob && dotglob_was=1
  shopt -q nullglob && nullglob_was=1
  shopt -s nullglob dotglob
  for entry in "$dest"/*; do
    name="$(basename "$entry")"
    case "$name" in
      .git|.gitignore|AGENTS.md|formats|rules|requests|configs|agents|modules|src|scripts|registry.sqlite|registry.sqlite-journal|registry.sqlite-wal|registry.sqlite-shm)
        continue
        ;;
    esac
    move_entry "$name" "src/$name" "$name"
  done
  for entry in "$dest/scripts"/*; do
    name="$(basename "$entry")"
    [[ "$name" == "index-symbols.py" ]] && continue
    move_entry "scripts/$name" "src/scripts/$name" "$name"
  done
  if [[ "$dotglob_was" -eq 0 ]]; then
    shopt -u dotglob
  fi
  if [[ "$nullglob_was" -eq 0 ]]; then
    shopt -u nullglob
  fi
}

move_foreign

if [[ "$adopt" -eq 1 ]]; then
  echo "Indexing existing files."
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
    body_text='Adopted existing tree. Files indexed. Foreign files moved into src.'
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

echo "Ready:"
echo "  $dest"
echo "Repository: $login/$name"
