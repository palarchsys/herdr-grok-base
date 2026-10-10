# Agent format.

```
name: <name>
module: <module>
config: <key>
llm: grok-build
workspace: <result.workspace.workspace_id>
tab: <result.tab.tab_id>
pane: <result.root_pane.pane_id>
worktree: <result.worktree.path>
start: <epoch>
end:
```

Live file: `agents/<name>.md`.
Done, after the commit: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. That closes that worker workspace, its tab, and its pane. The git branch stays. Do not close the orchestrator tab. Workspace already gone: `git worktree remove` the checkout. Untracked files after that commit: `git worktree remove --force` that path. Do not reuse that tab or pane.
Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. Do not reuse tab or pane.
Impl name = `<module>`. Plan name = `<module>-plan`.
