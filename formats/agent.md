# Agent format.

```
name: <name>
module: <module>
config: <key>
llm: grok-build
tab: <Herdr tab id>
pane: <Herdr pane id>
worktree: <path returned by herdr worktree create>
start: <epoch>
end:
```

Live file: `agents/<name>.md`.
Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, do not reuse tab or pane.
Impl name = `<module>`. Plan name = `<module>-plan`.
