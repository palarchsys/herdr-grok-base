# scripts sync

## Move

When the destination already has entries (existing directory or cloned repo), after the scaffold and before the index:

- Never move: `.git`, `.gitignore`, `AGENTS.md`, `formats`, `rules`, `requests`, `configs`, `agents`, `modules`, `src`, `scripts`, `registry.sqlite`, `registry.sqlite-journal`, `registry.sqlite-wal`, `registry.sqlite-shm`.
- Every other root entry moves to `src/<name>`. If `src/<name>` exists, print `left in place: <name>` and skip.
- Other files in `scripts/` besides `index-symbols.py` move to `src/scripts/<name>` with the same collision rule.
- Tracked path: `git mv`. Otherwise `mv`.
- An empty `gh repo create --clone` has nothing to move.
- Do not move the protocol root. The refusal stays before `gh`.
- A cloned repo's `CLONE_MARKER` moves to `src/CLONE_MARKER`.

## Overwrite

From the protocol root, even when the file exists: `AGENTS.md`, every file in `formats/`, `scripts/index-symbols.py`.

- Print `AGENTS.md installed` or `AGENTS.md updated`.
- Print `formats installed` or `formats updated`.
- Print `index-symbols.py installed` or `index-symbols.py updated`.
- Append any missing `registry.sqlite` gitignore lines. Do not replace the rest. Do not move `.gitignore`.

`check.sh`: replace the `AGENTS.md kept` assertion and the mtime check with content equal to the protocol `AGENTS.md` and the text `AGENTS.md updated`.

## update.sh

Add `scripts/update.sh`. Root is the parent of `scripts/`.

- `git -C root pull --ff-only`. No origin, or a dirty tree: exit 1 and say why.
- Each directory in `projects/*` gets the same overwrite of `AGENTS.md`, `formats/*`, `scripts/index-symbols.py`, the schema, and the gitignore lines.
- Do not move foreign files. Do not clone.
- Repeat until the answer is Oui or Non (`Oui` `oui` `O` `o` / `Non` `non` `N` `n`).
- `Mise a jour des readmes ? Oui/Non :` — Oui copies root `README.md` over each `projects/<name>/README.md`. Non goes to the next question.
- `Commit et push vers le depot ? Oui/Non :` — Oui prompts `Commentaire : `. An empty comment exits 1. For root and each `projects/*` that has `.git`, when the tree is dirty: `git add -A`, commit with that message, `git push`. A clean repo is skipped. A push failure exits 1. Non exits 0.
- `check.sh` proves this with a local bare remote. No network and no real push.
- Shellcheck includes `scripts/update.sh`.

## Smoke

`herdr worktree create --cwd` on the temp repo also leaves a workspace on that repo. In cleanup, before `rm -rf` of the temp dir: `herdr workspace list`, then `herdr workspace close` for every workspace whose `checkout_path` or `repo_root` is inside that temp dir. Do the same after the smoke test and assert that none remain. Do not close any other workspace. Keep the linked worktree remove.

## README

French. Document the move, the overwrite, `scripts/update.sh`, the two questions, and that `check.sh` closes Herdr workspaces under its temp dir. Delete the sentences that say nothing is moved and that an existing `AGENTS.md` is kept.
