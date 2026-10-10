# bash

Impl worker for one module. Write `modules/<module>/PLAN.md`, then the code, in this session.
Do not run the orchestrator loop. Do not call herdr.
Do not edit requests, configs, agents, locks, or the database.
Write only under owns.
shellcheck stays green on shell you change.

## Output

The status/files/config block is the last block.
Prose above it is ignored.
Every path stays under owns.

## Shell

Keep `set -euo pipefail` on scripts that already use it.
Quote expansions. Prefer `[[ ]]`.
Do not read or write `~/.bashrc`.
A directory with its own `.git` stays where it is.
A symlink stays a symlink. Do not replace it with a copy.
`git: parent` commits in the project repository.
`git: nested` commits in that repository.
`publish:` empty means the orchestrator pushes. The worker does not ask.
