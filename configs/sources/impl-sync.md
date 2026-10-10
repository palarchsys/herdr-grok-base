# sync

Impl worker. Read modules/scripts/PLAN.md and implement it.
Do not run the orchestrator loop. Do not call herdr except inside check.sh.
Do not edit AGENTS.md, install.sh, or index-symbols.py.
Run bash scripts/check.sh from the scripts parent. It prints check ok. shellcheck stays green.

## Create

In scripts/new-project.sh, when the destination already contains entries
(existing directory or cloned repo):

Root allowlist, never moved: .git .gitignore AGENTS.md formats rules
requests configs agents modules src scripts registry.sqlite
registry.sqlite-journal registry.sqlite-wal registry.sqlite-shm.

Overwrite from the protocol root even when the file exists:
AGENTS.md, every file in formats/, scripts/index-symbols.py.
Print `AGENTS.md installed` or `AGENTS.md updated`.
Print `formats installed` or `formats updated`.
Print `index-symbols.py installed` or `index-symbols.py updated`.
Append any missing registry.sqlite gitignore lines. Do not replace the rest.
Do not move .gitignore.

Every other root entry moves to src/<name>.
If src/<name> already exists, print `left in place: <name>` and skip it.
Other files in scripts/ besides index-symbols.py move to src/scripts/<name>
with the same collision rule.
Tracked path: git mv. Otherwise mv.
Move after the scaffold and before the index, so the index sees src/.
An empty `gh repo create --clone` has nothing to move.
Do not move the protocol root. The refusal stays before gh.

Replace the check.sh assertion `AGENTS.md kept` and the mtime check
with content equal to the protocol AGENTS.md and the text `AGENTS.md updated`.
A cloned repo's CLONE_MARKER moves to src/CLONE_MARKER.

## Update

Add scripts/update.sh. root is the parent of scripts/.
`git -C root pull --ff-only`. No origin, or a dirty tree: exit 1 and say why.
Then each directory in projects/* gets the same overwrite of AGENTS.md,
formats/*, scripts/index-symbols.py, the schema, and the gitignore lines.
Do not move foreign files. Do not clone.

Then ask, and repeat until the answer is Oui or Non
(Oui oui O o / Non non N n):

Mise a jour des readmes ? Oui/Non :
Oui: copy root README.md over each projects/<name>/README.md.
Non: next question.

Commit et push vers le depot ? Oui/Non :
Oui: prompt `Commentaire : `. An empty comment exits 1.
For root and each projects/* that has .git, when the tree is dirty:
git add -A, commit with that message, git push.
A clean repo is skipped. A push failure exits 1.
Non: exit 0.

check.sh proves this with a local bare remote. No network and no real push.
Shellcheck includes scripts/update.sh.

## Smoke

`herdr worktree create --cwd` on the temp repo also leaves a workspace on
that repo. check.sh removes only the linked worktree, then deletes the temp
dir, so Herdr shows `smoke (deleted)`.

In cleanup, before `rm -rf` of the temp dir: `herdr workspace list`, then
`herdr workspace close` for every workspace whose checkout_path or repo_root
is inside that temp dir. Do the same after the smoke test and assert that
none remain. Do not close any other workspace.
Keep the linked worktree remove.

## README

French. Document the move, the overwrite, scripts/update.sh, the two
questions, and that check.sh closes Herdr workspaces under its temp dir.
Delete the sentences that say nothing is moved and that an existing
AGENTS.md is kept.
