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
Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. Do not reuse tab or pane.
Impl name = `<module>`. Plan name = `<module>-plan`.
