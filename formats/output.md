# Worker output.

Prose above the block is ignored.
The last block is:

```
status: done|failed
files:
  - <path>
config: <key>
```

Fail when a path is outside `owns`, an announced file is missing, or `check` fails.
`done` only if every path is under `owns`.
`split: plan` plan agent: only allowed path `modules/<module>/PLAN.md`.
Orchestrator appends this block under `requests/<id>.md`, after a blank line.
The block is an annex. It is not a request field.
