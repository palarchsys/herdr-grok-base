# scripts pull gate

## Gate

`scripts/update.sh`. Root is the parent of `scripts/`.

- No `origin`: print `No origin.` and exit 1. This stays before the pull.
- Do not reject a dirty tree before `git pull --ff-only`.
- Pull exit 0: continue, even when a protocol path outside `projects/` is dirty. Then the same overwrite of each `projects/*` and the same two questions.
- Pull exit non-zero, and a protocol path outside `projects/` is dirty: print `Dirty tree.`, then each of those paths, one per line, and exit 1. Do not refresh `projects/`. Leave file bytes as they were.
- Pull exit non-zero and the protocol tree is clean: print the git error and exit 1.
- Dirty paths come from `git status --porcelain`. Drop the `XY ` prefix. A rename uses the path after ` -> `. Strip quotes. `projects` and `projects/*` stay out of the set.
- Do not change the questions, the commit paths, or `new-project.sh`.
- Do not change `install.sh` or `index-symbols.py`.

## Tests

In `check.sh`, with no network:

- Missing origin still prints `No origin.`
- Dirty tree and a missing remote still print `Dirty tree.`
- Dirty tree, real bare origin, HEAD not behind: answers `Non` then `Non`, exit 0, and the output has no `Dirty tree.`
- Dirty tracked file, origin one commit ahead that edits that file: exit 1, output contains `Dirty tree.` and that path, file bytes unchanged.
- The clean local bare pull, overwrite, readme, and commit tests stay.

## README

French, in `src/README.md`.

- A dirty tree does not stop `scripts/update.sh` when `git pull --ff-only` succeeds.
- When pull fails because the protocol tree is dirty, the script exits 1, prints `Dirty tree.`, and lists the paths.
- No `origin` still exits 1. Paths under `projects/` still do not make the root dirty.
