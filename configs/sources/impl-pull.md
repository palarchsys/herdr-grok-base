# pull

Impl worker. Read modules/scripts/PLAN.md and implement it.
Do not run the orchestrator loop. Do not call herdr except inside check.sh.
Do not edit AGENTS.md, install.sh, index-symbols.py, or new-project.sh.
From the directory that contains scripts/, run bash scripts/check.sh.
It must print check ok. shellcheck scripts/update.sh stays green.
Then emit the status block and stop.

## Gate

scripts/update.sh. Root is the parent of scripts/.
No origin: print `No origin.` and exit 1.

Do not reject a dirty tree before `git pull --ff-only`.
Pull exit 0: continue, even if a protocol path outside `projects/` is dirty.
Then the same overwrite of each `projects/*` and the same two questions.

Pull exit non-zero, and a protocol path outside `projects/` is dirty:
print `Dirty tree.`, then each of those porcelain paths, one per line, and exit 1.
Do not refresh projects.
Pull exit non-zero and the protocol tree is clean: print the git error and exit 1.

`projects/` and `projects/*` stay out of the dirty set.
Do not change the questions or the commit paths.

## Tests

In check.sh, with no network:
- Missing origin still prints `No origin.`
- Dirty tree and a missing remote still print `Dirty tree.`
- Dirty tree, real bare origin, HEAD not behind: answers `Non` then `Non`, exit 0, and the output has no `Dirty tree.`
- Dirty tracked file, origin one commit ahead that edits that file: exit 1, output contains `Dirty tree.` and that path, file bytes unchanged.
- The clean local bare pull, overwrite, readme, and commit tests stay.

## README

French. State that a dirty tree does not stop `scripts/update.sh` when `git pull --ff-only` succeeds.
When pull fails because the protocol tree is dirty, the script exits 1, prints `Dirty tree.`, and lists the paths.
