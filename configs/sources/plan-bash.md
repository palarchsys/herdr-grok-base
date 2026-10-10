# bash

Plan worker. Write only modules/scripts/PLAN.md.
Do not run Herdr. Do not insert requests. Do not edit src.
Ignore the orchestrator loop in AGENTS.md.

PLAN.md states the behavior below. The impl worker follows it.

## bashrc

Remove every read and write of ~/.bashrc from scripts/new-project.sh.
Remove the herdr-<name> function and the herdr-grok-base:<name> markers.
Do not print source ~/.bashrc.
End with these lines only:

Ready:
  <dest>
Repository: <login>/<name>

## GitHub

Require gh beside git, sqlite3, rg, and python3.
login is `gh api user --jq .login`. Failure exits 1.
A repo exists when `gh repo view "$login/$name" --json name` exits 0.
It is absent when that command fails and the output contains "Could not resolve".
Any other failure exits 1.

Keep the name prompt and the existing-directory prompt.
If dest is the protocol root, exit 1 before any clone or repo create.

If dest does not exist and the repo exists:
`gh repo clone "$login/$name" "$dest"`, then scaffold missing files, then index.
Do not overwrite a file that is already there.

If dest does not exist and the repo is absent:
mkdir -p the projects directory, then
`(cd projects && gh repo create "$name" --private --clone)`, then scaffold a new project.
Do not index that empty clone.

If dest already exists:
do not clone.
Scaffold as the script does today.
Index when the directory was already there.
If the repo is absent and origin is missing:
`gh repo create "$name" --private --source "$dest" --remote origin`.
Omit --remote when origin exists. Never pass --push.
If the repo exists and origin is missing:
url from `gh repo view "$login/$name" --json url --jq .url`, then
`git -C "$dest" remote add origin "${url}.git"`.
If origin exists, leave it.

Run git init only when .git is missing.
The new repo is private. Never pass --public.

## Tests

check.sh keeps a temporary HOME and must not change ~/.bashrc.
Delete the bashrc function, update, and legacy tests.
A fake gh on PATH handles api, repo view, repo clone, and repo create with no network.
Prove: an existing repo is cloned into projects/<name>;
a missing repo runs `gh repo create <name> --private --clone`;
an existing directory is not cloned over and uses --source when the repo is missing.
Keep the schema, symbol, adopt, protocol-root refusal, and Herdr worktree tests.
bash scripts/check.sh prints check ok.
Do not change scripts/install.sh or scripts/index-symbols.py.

## README

In French, delete bashrc and herdr-<name>.
Document the GitHub check, the clone, the private create, and the in-place prepare.
