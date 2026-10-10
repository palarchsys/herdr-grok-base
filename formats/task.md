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

Excerpts: `symbols`, then `rg`. 3 files, 40 lines. Tech source pasted, 80 lines max.
Send: `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000`.
Ready agents start together: one prompt process in the background per agent. `wait -n` when the next one exits. Do not chain `--wait`. Do not `wait` for every plan before any impl.
First prompt: config preprompt, then this block. Later: this block only.
