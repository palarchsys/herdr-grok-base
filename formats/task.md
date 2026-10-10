# Task. Copy. Fill. Add nothing.

```
id: <depth 2 id>
module: <module>
config: <key>
owns: src/<module>/**
done: <one sentence>
forbidden: outside owns, registries, neighbor agent, tab, sqlite
excerpts:
  - <path>:<start>-<end>
output: status, files, config
```

Excerpts: `symbols`, then `rg`. 3 files, 40 lines. A `laws:` path is pasted in full and does not count. A file this task edits, under 200 lines, is pasted in full and does not count. Tech source pasted, 80 lines max.
One agent. `split: plan` is the only case with a plan agent, then an impl agent.
Send: `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000`.
Ready agents with empty `imports` start together: one prompt process in the background per agent. `wait -n` when the next one exits. Do not chain `--wait`. `split: plan`: do not `wait` for every plan before any impl.
First prompt: config preprompt, laws, `rules/AGENT-*.md`, then this block. Later: this block, plus the error on a retry.
The status/files/config block is the last block. Prose above it is ignored.
