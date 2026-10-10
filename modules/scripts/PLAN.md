# scripts plan

Impl edits only `src/scripts/new-project.sh`, `src/scripts/check.sh`, and `src/README.md`.
Do not edit `src/scripts/install.sh` or `src/scripts/index-symbols.py`.
Do not read or write `~/.bashrc`. Never pass `--public` or `--push`.

`bash scripts/check.sh` must print `check ok`. That run already executes `bash -n` and `shellcheck -s bash` on `scripts/new-project.sh` and `scripts/check.sh`. New code passes both.

## src/scripts/new-project.sh

### Tools and prompts

Require `gh` in the same check as `git`, `sqlite3`, `rg`, and `python3`. A missing command still prints `Missing: … Run scripts/install.sh first.` and exits 1.

Keep both prompts and the current validation:

- name must match `^[a-z][a-z0-9-]{0,24}$`, else `Invalid name.` and exit 1
- a non-empty existing-directory answer that is not a directory: `Directory not found: <given>` and exit 1
- empty answer: `dest` is `<protocol-root>/projects/<name>`
- non-empty answer: `dest` is the absolute path of that directory

If `dest` is the protocol root, print `Refusing the protocol repository.` and exit 1 before `gh api`, `gh repo view`, `gh repo clone`, and `gh repo create`. Write nothing.

### Remove bashrc

Delete `bashrc`, `fn`, and the whole block that reads or writes `~/.bashrc` (the `herdr-<name>` function and the `# herdr-grok-base:<name>` / `# herdr-grok-base:<name>:end` markers).

Do not print `source ~/.bashrc`. Replace the closing `Launch:` / `Directory:` lines with only:

```
Ready:
  <dest>
Repository: <login>/<name>
```

`<dest>` is indented two spaces. Keep the earlier scaffold messages (`AGENTS.md kept`, `formats/ kept`, `database created`, `git kept`, and the adopt lines). They are not part of this closing block.

### Login and repo state

After the protocol-root refusal:

`login` is the stdout of `gh api user --jq .login`. A non-zero status or an empty login exits 1.

Then run `gh repo view "$login/$name" --json name` and keep stdout and stderr together.

- exit 0: the repo exists
- non-zero and the combined output contains `Could not resolve`: the repo is absent
- any other failure: exit 1

Do this before any `mkdir` of `dest`, any clone, and any repo create.

### Scaffold

Reuse today's scaffold. Never replace a file that is already there.

That is: create `requests`, `configs/sources`, `agents/closed`, `modules`, `src`, `formats`, `rules`; copy `AGENTS.md` only when missing; copy each missing file under `formats/`; create `registry.sqlite` from `formats/registry.sql` when missing, and re-apply that schema when it is already there; write `.gitignore` only when missing; copy `scripts/index-symbols.py` only when missing.

Run `git -C "$dest" init -b main` only when `$dest/.git` is missing. When `.git` is present, print `git kept` and do not init.

### dest is absent

This branch is only the default `projects/<name>`. A typed path that is not a directory has already exited.

Parent directory: `mkdir -p "$root/projects"`. Do not create `dest` itself before `gh` does.

Repo exists:

`gh repo clone "$login/$name" "$dest"`. Then scaffold. Then index. Do not run the origin repair below. `gh repo clone` sets `origin`. Leave it.

Repo absent:

`(cd "$root/projects" && gh repo create "$name" --private --clone)`. Then scaffold. Do not index. Do not write `requests/r-adopt-0.md`. Do not run `scripts/index-symbols.py`. Do not run the origin repair below.

### dest already exists

Do not clone. Scaffold as today. Index, because the directory was already there.

After `git init` (only if `.git` was missing), `origin` exists when `git -C "$dest" remote get-url origin` exits 0.

- repo absent, origin missing: `gh repo create "$name" --private --source "$dest" --remote origin`
- repo absent, origin present: `gh repo create "$name" --private --source "$dest"` and omit `--remote`
- repo present, origin missing: `url` is stdout of `gh repo view "$login/$name" --json url --jq .url`. Failure exits 1. Then `git -C "$dest" remote add origin "${url}.git"`
- repo present, origin present: do not change the remote

### Index

Index means the current `adopt=1` block, unchanged: `rg` the tree, `INSERT OR IGNORE` into `files`, write a missing `MODULE.md` only, write `requests/r-adopt-0.md` and its `requests` row only when that file is missing, run `python3 scripts/index-symbols.py` per module, print `Adopted. Modules written only where missing.`

Run it in two cases: `dest` was already there, or `dest` was cloned from an existing repo. Skip it for the empty `gh repo create --private --clone`.

## src/scripts/check.sh

Keep the temporary `HOME` and the fake `git` on `$HOME/.local/bin`. Do not change the real `~/.bashrc`. Before switching `HOME`, hash `"$real_home/.bashrc"` when that file exists. At the end, the hash matches, and `$HOME/.bashrc` under the temporary home was never created.

Delete the bashrc function test, the marker counts, the `command herdr-… already in bashrc` assertion, the Python bashrc rewrite, the `command herdr-… updated` test, and the legacy `~/.bashrc` test. Keep the second run of the fresh project that asserts `AGENTS.md kept` and an unchanged `AGENTS.md` mtime. Assert the no-index result before that second run.

Keep, without behavior changes: schema, symbol, vue lang, adopt, protocol-root refusal, and the Herdr worktree create/remove test. The adopt path now hits `gh` because that directory already exists and the repo is absent. The fake must succeed and must not modify the adopted tree.

### Fake gh

Put `gh` in `$HOME/.local/bin`, ahead of the real `gh`. No network. Log every invocation. Login printed for `api user --jq .login` is `tester`.

- `repo view <login>/<name> --json name`: exit 0 and print a name JSON when that name is marked present. If marked as a hard failure, exit 1 and print `HTTP 401` with no `Could not resolve`. Otherwise exit 1 and print `Could not resolve to a Repository with the name '<login>/<name>'.`
- `repo view <login>/<name> --json url --jq .url`: when present, print `https://github.com/<login>/<name>` with no `.git` suffix.
- `repo clone <login>/<name> <dest>`: `git init -b main` in `dest`, `remote add origin https://github.com/<login>/<name>.git`, write `CLONE_MARKER` containing `clone-marker`, mark the repo present.
- `repo create`: exit 1 if the arguments contain `--public` or `--push`. With `--clone`, `git init -b main` in `./<name>` under the current directory, add the same origin, mark the repo present, and do not write `requests/`. With `--source`, exit 0, mark the repo present, and do not create or edit files.

### Proofs

Missing repo, default dest: the fresh project. The log contains `repo create <name> --private --clone`. It does not contain `--public` or `--push`. `projects/<name>` has `AGENTS.md`, `formats/symbols.md`, `registry.sqlite`, branch `main`, and a gitignored `registry.sqlite`. `requests/r-adopt-0.md` is absent until a later run.

Existing repo: mark the name present, then run with an empty directory answer. The log contains `repo clone tester/<name> <protocol-root>/projects/<name>`. `CLONE_MARKER` is still `clone-marker`. `AGENTS.md` was added. `requests/r-adopt-0.md` exists. The log has no `repo create` for that name.

Existing directory, repo absent: a directory outside `projects/` with a sentinel file, and no `.git`. The log contains `repo create <name> --private --source <dest> --remote origin`. The log has no `repo clone` for that name. The sentinel is unchanged. `requests/r-adopt-0.md` exists.

Other view failure: mark a name as a hard failure. The run exits 1. `projects/<name>` is not created. The log has no clone and no create for that name.

Protocol root: the refused run exits 1, writes no `registry.sqlite` and no `requests/` at the root, and the log has no `repo clone` and no `repo create`.

## src/README.md

French. In `## Nouveau projet`, delete `source ~/.bashrc && herdr-<name>` and the sentence that `herdr-<name>` opens Herdr. Leave the rest of the file, including the `herdr-grok-base/` tree and the rules paragraph.

State there:

- `gh` is required beside `git`, `sqlite3`, `rg`, and `python3`. Login is `gh api user --jq .login`. Failure stops the script.
- The repo exists when `gh repo view <login>/<name> --json name` exits 0. It is absent when that command fails and the output contains `Could not resolve`. Any other failure stops the script.
- The name prompt and the existing-directory prompt stay. The protocol root exits 1 before any clone or repo create.
- If `projects/<name>` is absent and the repo exists: `gh repo clone <login>/<name>` into that directory, scaffold missing files, then index. An existing file is not replaced.
- If `projects/<name>` is absent and the repo is absent: `mkdir` of `projects`, then `(cd projects && gh repo create <name> --private --clone)`, then scaffold. That empty clone is not indexed.
- If the directory already exists: no clone. Scaffold as before, then index. Repo absent and `origin` missing: `gh repo create <name> --private --source <dest> --remote origin`. `origin` already present: the same command without `--remote`. Never `--push`, never `--public`. Repo present and `origin` missing: URL from `gh repo view <login>/<name> --json url --jq .url`, then `git remote add origin <url>.git`. `origin` present: leave it. `git init` only when `.git` is missing.
- The script ends with `Ready:`, the destination, and `Repository: <login>/<name>`.
