# Worker output. Only accepted text.

```
status: done|failed
files:
  - <path>
config: <key>
```

Any other text = `failed`.
`done` only if every path is under `owns`.
Plan agent: only allowed path `modules/<module>/PLAN.md`.
Orchestrator copies this block to the bottom of `requests/<id>.md`.
