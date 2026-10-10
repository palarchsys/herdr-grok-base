# scripts origin pull

## Pull

`scripts/update.sh`. Root is the parent of `scripts/`.

- No `origin`: print `No origin.` and exit 1. This stays before the pull.
- Detached HEAD: print `Detached head.` and exit 1 before the pull.
- Pull is `git pull --ff-only origin <branch>`. `<branch>` is the current branch. Do not require an upstream. A missing upstream is not `Dirty tree.`
- Not protocol dirt, never listed: `.Trash-1000`, `.Trash-1000/`, `.Trash-1000/*`, `.idea`, `.idea/`, `.idea/*`, `projects`, `projects/*`.
- Pull exit 0: continue, even when another protocol path is dirty. Then the same overwrite and the same two questions.
- Pull exit non-zero and a protocol path remains: print `Dirty tree.`, then each remaining path, one per line, exit 1. Do not refresh `projects/`. Leave file bytes as they were.
- Pull exit non-zero and no protocol path remains: print the git error and exit 1.
- The root `git add` skips `projects`, `.Trash-1000`, and `.idea`.
- Do not change the questions, `new-project.sh`, `install.sh`, or `index-symbols.py`.

## Tests

In `check.sh`, no network:

- Missing origin still prints `No origin.`
- A dirty tracked file and a missing remote still print `Dirty tree.`
- No upstream, real bare origin, not behind, only `.Trash-1000/` and `.idea/`: `Non` then `Non`, exit 0, no `Dirty tree.`
- Only `.Trash-1000/` and a missing remote: exit 1, no `Dirty tree.`
- Dirty tracked file, origin one commit ahead on that file: exit 1, `Dirty tree.` and that path, bytes unchanged.
- An up-to-date dirty file that has an upstream still exits 0.
- The clean local bare pull, overwrite, readme, and commit tests stay.

## README

French, in `src/README.md`.

- Pull is `git pull --ff-only origin` plus the current branch. No upstream is required.
- `.Trash-1000/` and `.idea/` do not make the tree dirty and are not committed.
- No `origin` still exits 1 and prints `No origin.`. Detached HEAD exits 1 and prints `Detached head.`.
- Pull exit 0 continues. A failed pull with a remaining protocol path prints `Dirty tree.` and those paths. A failed pull with none prints the git error.
- Paths under `projects/` still do not make the root dirty. The script still clones nothing and moves no foreign file.
