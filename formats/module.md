# Module format.

```
id: <module>
owns:
  - src/<module>/**
  - modules/<module>/PLAN.md
laws: []
imports: []
events_in: []
events_out: []
check:
publish:
git: parent
split:
forbidden:
  - write outside owns
  - read requests, agents, locks, or the database
  - call an agent
  - open a tab
```

File: `modules/<module>/MODULE.md`.
Id: `[a-z][a-z0-9-]{0,24}`.
Concerns: graphics, database, ux, core, or another disjoint area. Disjoint owns inside one concern are several modules and run together. Overlapping files stay one module. No module that writes nothing.
Export change = depth 2 to the owner. No neighbor edit.
Default: one agent writes `modules/<module>/PLAN.md`, then the code, in one worktree.
`split: plan` keeps a plan agent, then an impl agent. Absent means one agent.
`laws:` paths are pasted in full in the first prompt. They do not count toward the 3 excerpts. Empty means the prompt does not grow.
`imports:` module ids. Each is merged before this module starts. The prompt receives at most 50 file names: paths named in the task, or the first 50 sorted, then `<n> more`. Empty, with disjoint owns, means the agents start together.
`check:` command run by the orchestrator after the commit, before the merge. Empty means no command.
`publish:` command for a later `git` message. Empty means `git add` the owns, `git commit` with the given comment, `git push` in the project repository. Set means that command receives the comment.
`git: parent` commits and merges in the project repository.
`git: nested` is set only when that directory has its own `.git`. The worktree and the commit stay in that repository. The parent merge skips those paths.
The worker may read `rules/AGENT-*.md` and its `laws:`. It does not read `requests/`, `agents/`, `locks`, or the database.
