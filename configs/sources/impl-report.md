# report

Impl worker. Read modules/scripts/PLAN.md and implement it.
Do not run the orchestrator loop. Do not call herdr except inside check.sh.
Do not edit AGENTS.md, install.sh, index-symbols.py, or new-project.sh.
From the directory that contains scripts/, run bash scripts/check.sh.
It must print check ok. shellcheck scripts/update.sh stays green.
Then emit the status block and stop.

## Report

scripts/update.sh. After a successful pull, each directory in projects/*.

Print `<name>: updated` or `<name>: current`. `<name>` is the basename.
Under `updated`, one relative path per line, indented two spaces, only paths that differed or were missing:
`AGENTS.md`, `formats/<file>` in basename order, `scripts/index-symbols.py`, `.gitignore`, `registry.sqlite`.
Identical bytes are not copied. A `current` project lists nothing.

Missing `registry.sqlite` is created and listed. An existing one gets the schema and is not listed, and does not by itself make the project updated.
`.gitignore` is listed only when a registry line was missing and appended.

## Drop

Delete the two questions, the readme copy, the comment prompt, and every commit and push.
The script reads no stdin. It does not print `Mise a jour des readmes` or `Commit et push vers le depot`.
Do not change the pull or the junk exclusion.

## Tests

No network. check.sh no longer feeds Oui, Non, or a comment to prove a commit.
- A stale project prints `<name>: updated` and `AGENTS.md`. Its README stays. Its HEAD stays.
- A second run prints `<name>: current`.
- A project whose protocol files already match prints `<name>: current` on the first run.
- A normal update prints neither question.
- A dirty tree is not committed.
- A bad project remote does not fail the update.
- Pull tests stay: no origin, dirty remote, trash without upstream, trash-only missing remote, detached head, blocked pull.

## README

French. Delete the two questions, the readme copy, and the commit.
Document `<name>: updated` and `<name>: current`.
