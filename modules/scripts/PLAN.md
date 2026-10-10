# scripts project report

## Report

`scripts/update.sh`. After a successful pull, each directory in `projects/*`. `<name>` is the basename.

- Print `<name>: updated` or `<name>: current`. Under `updated`, one relative path per line, two spaces of indent. `current` lists nothing.
- Order, omitting a path that did not change: `AGENTS.md`, `formats/<file>` in basename order, `scripts/index-symbols.py`, `.gitignore`, `registry.sqlite`.
- Copy `AGENTS.md`, each `formats/<file>`, and `scripts/index-symbols.py` only when missing or bytes differ. Identical bytes are not copied. Do not remove other project files.
- Missing `registry.sqlite` is created from `formats/registry.sql` and listed. An existing database gets that schema, is not listed, and does not by itself make the project updated.
- `.gitignore` keeps its other lines. List it only when `registry.sqlite`, `registry.sqlite-journal`, `registry.sqlite-wal`, or `registry.sqlite-shm` was missing and was appended. Do not copy another `.gitignore` over it.
- Drop the old lines `AGENTS.md updated`, `AGENTS.md installed`, `formats updated`, `formats installed`, `index-symbols.py updated`, `index-symbols.py installed`, `database created`, and `registry.sqlite kept, schema ensured`.

## Drop

- Delete both questions, the readme copy, the comment prompt, `ask`, `commit_repo`, and every commit and push.
- The script reads no stdin. It does not print `Mise a jour des readmes`, `Commit et push vers le depot`, or `Empty comment.`
- Leave the pull, the junk exclusion, `new-project.sh`, `install.sh`, and `index-symbols.py` unchanged. Leave project `README.md` bytes unchanged.

## Tests

`check.sh`, no network. Do not feed `Oui`, `Non`, or a comment.

- A stale project prints `<name>: updated` and `AGENTS.md`. Its README stays. Its HEAD stays. A second run prints `<name>: current`.
- A project whose protocol files already match prints `<name>: current` on the first run.
- A normal update prints neither question. A dirty tree is not committed. A bad project remote does not fail the update.
- Pull tests stay: no origin, dirty remote, trash without upstream, trash-only missing remote, detached head, blocked pull.

## README

French, in `src/README.md`. Delete the two questions, the readme copy, and the commit. Document `<name>: updated` and `<name>: current`.
