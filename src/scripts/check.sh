#!/usr/bin/env bash
# Prove the protocol scripts and the Herdr commands they name.
# Uses a temporary HOME. Does not edit the real ~/.bashrc.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

missing=()
for cmd in sqlite3 rg git python3 shellcheck herdr ast-grep; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
  echo "Missing: ${missing[*]}. Run scripts/install.sh first."
  exit 1
fi

bash -n scripts/install.sh scripts/new-project.sh scripts/check.sh
shellcheck -s bash scripts/install.sh scripts/new-project.sh scripts/check.sh

if grep -q '/usr/local/bin/sg' scripts/install.sh; then
  echo "install.sh must not place sg on PATH."
  exit 1
fi
if ! grep -q 'state" == "current"' scripts/install.sh; then
  echo "install.sh must keep the grok integration only when it is current."
  exit 1
fi
if grep -q 'bashrc\|herdr-grok-base:' scripts/new-project.sh; then
  echo "new-project.sh still mentions bashrc"
  exit 1
fi

require_text() {
  local file="$1" text="$2"
  if ! grep -qF "$text" "$file"; then
    echo "Missing in $file: $text"
    exit 1
  fi
}

# shellcheck disable=SC2016
require_text AGENTS.md 'reply `protocol repo` and stop.'
require_text AGENTS.md 'herdr worktree create --branch mod-<name> --base main --label <name> --no-focus'
require_text AGENTS.md 'herdr worktree create --branch mod-<name> --base mod-<module>-plan --label <name> --no-focus'
require_text AGENTS.md 'herdr agent start <name> --kind grok --pane <pane> --'
require_text AGENTS.md 'herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000'
require_text AGENTS.md 'wall time is the slowest ready module, not the sum.'
require_text AGENTS.md 'Do not wait for every plan before any impl.'
require_text AGENTS.md 'wait -n'
require_text formats/task.md 'Do not chain'
require_text formats/module.md 'Disjoint owns inside one concern are several modules and run together.'
require_text README.md 'Le temps est celui du module le plus lent.'
require_text AGENTS.md 'herdr worktree remove --workspace <workspace> --force'
require_text AGENTS.md 'Do not close the orchestrator tab.'
require_text AGENTS.md 'git worktree remove'
require_text formats/agent.md 'Do not close the orchestrator tab.'
require_text README.md "L'onglet de l'orchestrateur reste ouvert."
require_text AGENTS.md "SELECT path, line FROM symbols WHERE name='<name>' AND path LIKE 'src/<module>/%'"
require_text formats/task.md 'herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000'
require_text formats/agent.md 'workspace: <result.workspace.workspace_id>'
require_text formats/symbols.md 'ext: vue'
require_text formats/symbols.md 'lang: script'

if grep -R -n --exclude-dir=.git --exclude=check.sh 'worktree remove --label' AGENTS.md formats README.md scripts >/dev/null; then
  echo "Stale --label removal remains."
  exit 1
fi

herdr worktree create --help >/dev/null
herdr worktree remove --help | grep -q -- '--workspace'
if herdr worktree remove --help | grep -q -- '--label'; then
  echo "This Herdr accepts --label on worktree remove. The protocol would be wrong."
  exit 1
fi
herdr agent start --help >/dev/null
herdr agent prompt --help | grep -q -- '--wait'
herdr agent prompt --help | grep -q -- '<TEXT>\|<text>'

schema="$(mktemp)"
sqlite3 "$schema" < formats/registry.sql
sqlite3 "$schema" < formats/registry.sql
python3 - "$schema" << 'PY'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
try:
    db.execute("INSERT INTO requests(hash,id,parent,depth,module,config,status) VALUES ('a','r', '', 3, '', '', 'open')")
    raise SystemExit("depth 3 was accepted")
except sqlite3.IntegrityError:
    pass
db.execute("INSERT INTO requests(hash,id,parent,depth,module,config,status) VALUES ('h1','r-1-0','',0,'','','open')")
try:
    db.execute("INSERT INTO requests(hash,id,parent,depth,module,config,status) VALUES ('h1','r-2-0','',0,'','','pointer')")
    raise SystemExit("duplicate hash was accepted")
except sqlite3.IntegrityError:
    pass
print("schema ok")
PY
indexes="$(sqlite3 "$schema" "SELECT name FROM sqlite_master WHERE type='index' AND name IN ('requests_parent','requests_module_status') ORDER BY name;")"
[[ "$indexes" == $'requests_module_status\nrequests_parent' ]]
rm -f "$schema"

sym="$(mktemp -d)"
printf 'export function add(a: number) {\n  return a\n}\nclass Box {}\n' > "$sym/mod.ts"
python3 - "$sym/mod.ts" << 'PY'
import json, subprocess, sys
path = sys.argv[1]
patterns = [
    "function $NAME($$$A) { $$$B }",
    "class $NAME { $$$B }",
]
found = set()
for pattern in patterns:
    raw = subprocess.check_output(
        ["ast-grep", "run", "-l", "ts", "-p", pattern, path, "--json"],
        text=True,
    )
    for match in json.loads(raw):
        name = match["metaVariables"]["single"]["NAME"]["text"]
        if "\n" in name or len(name) > 64:
            raise SystemExit(f"pattern captured a block: {pattern}")
        found.add(name)
if found != {"add", "Box"}:
    raise SystemExit(f"unexpected symbols: {found}")
print("symbols ok")
PY
rm -rf "$sym"
python3 - "$root/scripts/index-symbols.py" << 'PY'
import importlib.util
import sys
path = sys.argv[1]
spec = importlib.util.spec_from_file_location("index_symbols", path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
assert mod.script_ast_lang("") == "ts"
assert mod.script_ast_lang(" setup") == "ts"
assert mod.script_ast_lang(' setup lang="ts"') == "ts"
assert mod.script_ast_lang(" lang=tsx") == "ts"
assert mod.script_ast_lang(" lang=javascript") == "js"
assert mod.script_ast_lang(' lang="js"') == "js"
print("vue lang ok")
PY

work="$(mktemp -d)"
real_home="$HOME"
real_git="$(command -v git)"
bashrc_hash=""
if [[ -f "$real_home/.bashrc" ]]; then
  bashrc_hash="$(sha256sum "$real_home/.bashrc" | awk 'NR==1 {print $1}')"
fi
export HOME="$work/home"
mkdir -p "$HOME/.local/bin" "$HOME/gh-state/present" "$HOME/gh-state/fail"
cat > "$HOME/.local/bin/git" << EOF
#!/bin/bash
export HOME=$(printf '%q' "$real_home")
exec $(printf '%q' "$real_git") "\$@"
EOF
chmod 755 "$HOME/.local/bin/git"
cat > "$HOME/.local/bin/gh" << 'EOF'
#!/bin/bash
set -euo pipefail
log="$HOME/gh.log"
state="$HOME/gh-state"
mkdir -p "$state/present" "$state/fail"
printf '%s\n' "$*" >>"$log"

if [[ "${1:-}" == "api" && "${2:-}" == "user" && "${3:-}" == "--jq" && "${4:-}" == ".login" ]]; then
  printf 'tester\n'
  exit 0
fi

if [[ "${1:-}" == "repo" && "${2:-}" == "view" ]]; then
  slug="${3:-}"
  name="${slug##*/}"
  if [[ -e "$state/fail/$name" ]]; then
    printf 'HTTP 401\n'
    exit 1
  fi
  json="${5:-}"
  if [[ "${4:-}" == "--json" && "$json" == "name" ]]; then
    if [[ -e "$state/present/$name" ]]; then
      printf '{"name":"%s"}\n' "$name"
      exit 0
    fi
    printf "Could not resolve to a Repository with the name '%s'.\n" "$slug"
    exit 1
  fi
  if [[ "${4:-}" == "--json" && "$json" == "url" ]]; then
    if [[ -e "$state/present/$name" ]]; then
      printf 'https://github.com/%s\n' "$slug"
      exit 0
    fi
    printf "Could not resolve to a Repository with the name '%s'.\n" "$slug"
    exit 1
  fi
  printf 'HTTP 401\n'
  exit 1
fi

if [[ "${1:-}" == "repo" && "${2:-}" == "clone" ]]; then
  slug="${3:-}"
  dest="${4:-}"
  name="${slug##*/}"
  git init -b main "$dest"
  git -C "$dest" remote add origin "https://github.com/${slug}.git"
  printf 'clone-marker\n' >"$dest/CLONE_MARKER"
  : >"$state/present/$name"
  exit 0
fi

if [[ "${1:-}" == "repo" && "${2:-}" == "create" ]]; then
  for arg in "$@"; do
    if [[ "$arg" == "--public" || "$arg" == "--push" ]]; then
      exit 1
    fi
  done
  name="${3:-}"
  mode=""
  for arg in "$@"; do
    if [[ "$arg" == "--clone" ]]; then
      mode="clone"
    elif [[ "$arg" == "--source" ]]; then
      mode="source"
    fi
  done
  if [[ "$mode" == "clone" ]]; then
    git init -b main "$name"
    git -C "$name" remote add origin "https://github.com/tester/${name}.git"
    : >"$state/present/$name"
    exit 0
  fi
  if [[ "$mode" == "source" ]]; then
    : >"$state/present/$name"
    exit 0
  fi
  exit 1
fi

exit 1
EOF
chmod 755 "$HOME/.local/bin/gh"
export PATH="$HOME/.local/bin:${PATH}"
mkdir -p "$HOME"
server_pid=""
names=()
cleanup() {
  local name
  for name in "${names[@]}"; do
    rm -rf "$root/projects/$name"
  done
  if [[ -n "$server_pid" ]]; then
    herdr server stop >/dev/null 2>&1 || true
    kill "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

run_new() {
  local name="$1" given="$2"
  printf '%s\n%s\n' "$name" "$given" | bash "$root/scripts/new-project.sh"
}

fresh="chk${RANDOM}"
names+=("$fresh")
fresh_out="$(run_new "$fresh" "")"
fresh_dir="$root/projects/$fresh"
[[ -f "$fresh_dir/AGENTS.md" ]]
[[ -f "$fresh_dir/formats/symbols.md" ]]
[[ -f "$fresh_dir/registry.sqlite" ]]
[[ "$(git -C "$fresh_dir" symbolic-ref --short HEAD)" == "main" ]]
git -C "$fresh_dir" check-ignore -q registry.sqlite
[[ ! -e "$fresh_dir/requests/r-adopt-0.md" ]]
grep -qF "repo create $fresh --private --clone" "$HOME/gh.log"
if grep -F -e '--public' -e '--push' "$HOME/gh.log"; then
  echo "public or push was passed"
  exit 1
fi
if grep -q 'bashrc' <<<"$fresh_out"; then
  echo "bashrc still mentioned"
  exit 1
fi
closing="$(printf 'Ready:\n  %s\nRepository: tester/%s' "$fresh_dir" "$fresh")"
[[ "$(tail -n 3 <<<"$fresh_out")" == "$closing" ]]

agents_before="$(stat -c %Y "$fresh_dir/AGENTS.md")"
second="$(run_new "$fresh" "")"
grep -q "AGENTS.md kept" <<<"$second"
[[ "$(stat -c %Y "$fresh_dir/AGENTS.md")" == "$agents_before" ]]

present="cln${RANDOM}"
names+=("$present")
touch "$HOME/gh-state/present/$present"
run_new "$present" "" >/dev/null
present_dir="$root/projects/$present"
grep -qF "repo clone tester/${present} ${present_dir}" "$HOME/gh.log"
[[ "$(cat "$present_dir/CLONE_MARKER")" == "clone-marker" ]]
[[ -f "$present_dir/AGENTS.md" ]]
[[ -f "$present_dir/requests/r-adopt-0.md" ]]
if grep -qF "repo create ${present}" "$HOME/gh.log"; then
  echo "existing repo was created: $present"
  exit 1
fi

placed="dir${RANDOM}"
placed_dir="$work/placed-$placed"
mkdir -p "$placed_dir"
printf 'sentinel\n' >"$placed_dir/SENTINEL"
run_new "$placed" "$placed_dir" >/dev/null
placed_abs="$(cd "$placed_dir" && pwd)"
grep -qF "repo create ${placed} --private --source ${placed_abs} --remote origin" "$HOME/gh.log"
if grep -qF "repo clone tester/${placed}" "$HOME/gh.log"; then
  echo "existing directory was cloned: $placed"
  exit 1
fi
[[ "$(cat "$placed_dir/SENTINEL")" == "sentinel" ]]
[[ -f "$placed_dir/requests/r-adopt-0.md" ]]

broken="bad${RANDOM}"
names+=("$broken")
touch "$HOME/gh-state/fail/$broken"
if run_new "$broken" ""; then
  echo "hard view failure was accepted"
  exit 1
fi
[[ ! -d "$root/projects/$broken" ]]
if grep -qF "repo clone tester/${broken}" "$HOME/gh.log"; then
  echo "hard failure cloned"
  exit 1
fi
if grep -qF "repo create ${broken}" "$HOME/gh.log"; then
  echo "hard failure created"
  exit 1
fi

adopt="$work/adopted"
mkdir -p "$adopt/src/web" "$adopt/pkg" "$adopt/node_modules" "$adopt/dist"
printf 'export function add(){return 1}\n' > "$adopt/src/web/app.ts"
cat > "$adopt/src/web/App.vue" << 'EOF'
<template>
  <p/>
</template>
<script setup lang="ts">
export function add(a: number) {
  return a
}
</script>
EOF
cat > "$adopt/src/web/Plain.vue" << 'EOF'
<script setup>
export function plain() {
  return 1
}
</script>
EOF
printf 'readme\n' > "$adopt/pkg/readme.txt"
printf 'junk\n' > "$adopt/node_modules/left-pad.js"
printf 'built\n' > "$adopt/dist/app.js"
run_new adopted "$adopt" >/dev/null
map="$(sqlite3 "$adopt/registry.sqlite" "SELECT path || ' ' || module FROM files ORDER BY path;")"
grep -q 'src/web/app.ts web' <<<"$map"
grep -q 'pkg/readme.txt pkg' <<<"$map"
if grep -E 'node_modules|(^|[[:space:]])dist/' <<<"$map"; then
  echo "heavy directories were indexed:"
  echo "$map"
  exit 1
fi
grep -qF 'src/web/**' "$adopt/modules/web/MODULE.md"
grep -qF 'pkg/**' "$adopt/modules/pkg/MODULE.md"
[[ -f "$adopt/scripts/index-symbols.py" ]]
symbol="$(sqlite3 "$adopt/registry.sqlite" "SELECT name || ' ' || kind || ' ' || line FROM symbols WHERE path='src/web/app.ts' ORDER BY name;")"
grep -qx 'add function 1' <<<"$symbol"
vue_symbol="$(sqlite3 "$adopt/registry.sqlite" "SELECT name || ' ' || kind || ' ' || line FROM symbols WHERE path='src/web/App.vue' AND name='add';")"
[[ "$vue_symbol" == "add function 5" ]]
plain_symbol="$(sqlite3 "$adopt/registry.sqlite" "SELECT name || ' ' || kind || ' ' || line FROM symbols WHERE path='src/web/Plain.vue' AND name='plain';")"
[[ "$plain_symbol" == "plain function 2" ]]
summary="$(sqlite3 "$adopt/registry.sqlite" "SELECT summary FROM files WHERE path='src/web/app.ts';")"
[[ "$summary" =~ ^[0-9a-f]{12}$ ]]
row_before="$(sqlite3 "$adopt/registry.sqlite" "SELECT rowid FROM symbols WHERE path='src/web/app.ts' AND name='add';")"
mod_before="$(cat "$adopt/modules/web/MODULE.md")"
run_new adopted "$adopt" >/dev/null
[[ "$(cat "$adopt/modules/web/MODULE.md")" == "$mod_before" ]]
row_after="$(sqlite3 "$adopt/registry.sqlite" "SELECT rowid FROM symbols WHERE path='src/web/app.ts' AND name='add';")"
[[ "$row_before" == "$row_after" ]]
[[ "$(sqlite3 "$adopt/registry.sqlite" "SELECT summary FROM files WHERE path='src/web/app.ts';")" == "$summary" ]]
adopt_hash="$(sqlite3 "$adopt/registry.sqlite" "SELECT hash FROM requests WHERE id='r-adopt-0';")"
[[ "$adopt_hash" =~ ^[0-9a-f]{12}$ ]]
expect="$(printf '%s' 'Adopted existing tree. Files indexed. Source not moved.' | sha256sum | cut -c1-12)"
[[ "$adopt_hash" == "$expect" ]]
git -C "$adopt" check-ignore -q registry.sqlite

log_before="$(wc -l <"$HOME/gh.log")"
if run_new refused "$root"; then
  echo "protocol root was accepted"
  exit 1
fi
[[ ! -e "$root/registry.sqlite" ]]
[[ ! -d "$root/requests" ]]
log_after="$(tail -n +"$((log_before + 1))" "$HOME/gh.log" || true)"
if [[ -n "$log_after" ]]; then
  echo "protocol root called gh"
  printf '%s\n' "$log_after"
  exit 1
fi

repo="$work/smoke"
mkdir -p "$repo"
git -C "$repo" init -b main >/dev/null
printf 'smoke\n' > "$repo/README.md"
git -C "$repo" -c user.email=smoke@example.com -c user.name=smoke add README.md
git -C "$repo" -c user.email=smoke@example.com -c user.name=smoke commit -m init >/dev/null
server_up() {
  herdr status server 2>&1 | grep -q 'status: running'
}

was_running=0
if server_up; then
  was_running=1
else
  herdr server >"$work/server.log" 2>&1 &
  server_pid=$!
  ready=0
  for _ in $(seq 1 40); do
    if server_up; then
      ready=1
      break
    fi
    sleep 0.25
  done
  if [[ "$ready" -ne 1 ]]; then
    echo "Herdr server did not start"
    exit 1
  fi
fi
herdr worktree create --cwd "$repo" --branch mod-check --base main --label check --no-focus >"$work/out.json"
python3 - "$work/out.json" "$work/ids" << 'PY'
import json, sys
data = json.load(open(sys.argv[1]))
result = data["result"]
wid = result["workspace"]["workspace_id"]
tab = result["tab"]["tab_id"]
pane = result["root_pane"]["pane_id"]
path = result["worktree"]["path"]
if not (wid and tab and pane and path):
    raise SystemExit("missing worktree ids")
open(sys.argv[2], "w").write(wid + "\n" + path + "\n")
PY
wid="$(sed -n '1p' "$work/ids")"
wpath="$(sed -n '2p' "$work/ids")"
[[ -d "$wpath" ]]
herdr worktree remove --workspace "$wid" --force >/dev/null
if [[ -d "$wpath" ]]; then
  echo "worktree checkout remains: $wpath"
  exit 1
fi
if herdr workspace get "$wid" >/dev/null 2>&1; then
  echo "worker workspace still open: $wid"
  exit 1
fi
if ! git -C "$repo" show-ref --verify --quiet refs/heads/mod-check; then
  echo "worktree remove deleted branch mod-check"
  exit 1
fi
if [[ "$was_running" -eq 0 ]]; then
  herdr server stop >/dev/null 2>&1 || true
  kill "$server_pid" >/dev/null 2>&1 || true
  server_pid=""
fi

if [[ -n "$bashrc_hash" ]]; then
  now_hash="$(sha256sum "$real_home/.bashrc" | awk 'NR==1 {print $1}')"
  if [[ "$now_hash" != "$bashrc_hash" ]]; then
    echo "real bashrc changed"
    exit 1
  fi
elif [[ -e "$real_home/.bashrc" ]]; then
  echo "real bashrc was created"
  exit 1
fi
if [[ -e "$HOME/.bashrc" ]]; then
  echo "temporary bashrc was created"
  exit 1
fi

echo "check ok"
