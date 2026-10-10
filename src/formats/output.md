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
Orchestrator appends this block under `requests/<id>.md`, after a blank line.
The block is an annex. It is not a request field.
