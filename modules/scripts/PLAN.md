# One agent, empty options

## Default

One module, one branch `mod-<module>`, one worktree on `main`, one process.
That agent writes this plan, then the code, and the orchestrator makes one commit of the owns.
`git: parent`. Merge with `git merge --no-ff`.

## Message classes

`ask` is answered in the tab. No request, no agent, no worktree.
`git` is the orchestrator, with the comment already in the message.
`edit` is the only class that reaches modules.

## Options, empty unless the project sets them

`laws`, `imports`, `check`, `publish`, `split`.
`git: nested` only when a directory has its own `.git`. Do not move it. Ignore it in the parent. Commit inside that repository.
A symlink stays a symlink.
`publish` empty means a later `git` message commits the owns and pushes that repository. A set `publish` command is the project's own publish. The protocol does not name that command.

## Index

After the merge, once. Bash functions come from `function_definition`. No hash above 1 Mio. ast-grep receives the changed files.

## Check

`check` empty runs nothing. `check` set runs in the worktree after the commit, before the merge. Failure returns to the same agent, once.
