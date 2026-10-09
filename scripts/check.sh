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
require_text AGENTS.md 'herdr worktree remove --workspace <workspace> --force'
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
export HOME="$work/home"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/git" << EOF
#!/bin/bash
export HOME=$(printf '%q' "$real_home")
exec $(printf '%q' "$real_git") "\$@"
EOF
chmod 755 "$HOME/.local/bin/git"
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
run_new "$fresh" ""
fresh_dir="$root/projects/$fresh"
[[ -f "$fresh_dir/AGENTS.md" ]]
[[ -f "$fresh_dir/formats/symbols.md" ]]
[[ -f "$fresh_dir/registry.sqlite" ]]
[[ "$(git -C "$fresh_dir" symbolic-ref --short HEAD)" == "main" ]]
git -C "$fresh_dir" check-ignore -q registry.sqlite
if ! grep -qF "herdr-$fresh()" "$HOME/.bashrc"; then
  echo "bashrc function missing"
  exit 1
fi
begin="# herdr-grok-base:${fresh}"
end="# herdr-grok-base:${fresh}:end"
[[ "$(grep -cxF "$begin" "$HOME/.bashrc")" -eq 1 ]]
[[ "$(grep -cxF "$end" "$HOME/.bashrc")" -eq 1 ]]

agents_before="$(stat -c %Y "$fresh_dir/AGENTS.md")"
second="$(run_new "$fresh" "")"
grep -q "AGENTS.md kept" <<<"$second"
grep -q "command herdr-$fresh already in bashrc" <<<"$second"
[[ "$(stat -c %Y "$fresh_dir/AGENTS.md")" == "$agents_before" ]]

python3 - "$HOME/.bashrc" "$begin" "$end" << 'PY'
import pathlib, sys
path, begin, end = sys.argv[1:]
text = pathlib.Path(path).read_text()
start = text.index(begin)
stop = text.index(end, start)
block = text[start:stop]
old = "  cd /tmp/not-the-project || return 1\n"
if "  cd " not in block:
    raise SystemExit("cd line missing")
text = text[:start] + block.replace(block[block.index("  cd "):block.index(" || return 1\n")+len(" || return 1\n")], old) + text[stop:]
# duplicate the end marker, then a sentinel that must survive
stop = text.index(end, start)
insert_at = stop + len(end)
text = text[:insert_at] + "\n" + end + "\nKEEP_ME\n" + text[insert_at:]
pathlib.Path(path).write_text(text)
PY
updated="$(run_new "$fresh" "")"
grep -q "command herdr-$fresh updated" <<<"$updated"
[[ "$(grep -cF "$end" "$HOME/.bashrc")" -eq 1 ]]
[[ "$(grep -cF "KEEP_ME" "$HOME/.bashrc")" -eq 1 ]]
dest_q="$(printf '%q' "$fresh_dir")"
grep -qF "cd ${dest_q} " "$HOME/.bashrc"

legacy_dir="$work/legacy"
mkdir -p "$legacy_dir"
cat > "$HOME/.bashrc.legacy" << EOF
# herdr-grok-base:legacy
herdr-legacy() {
  cd /tmp/nope || return 1
  exec herdr
}
KEEP_LEGACY
tail line
EOF
mv "$HOME/.bashrc" "$HOME/.bashrc.full"
cp "$HOME/.bashrc.legacy" "$HOME/.bashrc"
run_new legacy "$legacy_dir" >/dev/null
[[ "$(grep -cF '# herdr-grok-base:legacy:end' "$HOME/.bashrc")" -eq 1 ]]
grep -qF 'KEEP_LEGACY' "$HOME/.bashrc"
grep -qF 'tail line' "$HOME/.bashrc"
grep -qF "cd $(printf '%q' "$legacy_dir") " "$HOME/.bashrc"
mv "$HOME/.bashrc.full" "$HOME/.bashrc"

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

if run_new refused "$root"; then
  echo "protocol root was accepted"
  exit 1
fi
[[ ! -e "$root/registry.sqlite" ]]
[[ ! -d "$root/requests" ]]

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
if [[ "$was_running" -eq 0 ]]; then
  herdr server stop >/dev/null 2>&1 || true
  kill "$server_pid" >/dev/null 2>&1 || true
  server_pid=""
fi

echo "check ok"
