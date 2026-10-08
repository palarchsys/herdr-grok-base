# Module format.

```
id: <module>
owns:
  - src/<module>/**
  - modules/<module>/PLAN.md
exports: []
imports: []
events_in: []
events_out: []
forbidden:
  - write outside owns
  - read requests configs agents locks rules
  - call an agent
  - open a tab
```

File: `modules/<module>/MODULE.md`.
Id: `[a-z][a-z0-9-]{0,24}`.
Export change = depth 2 to the owner. No neighbor edit.
`modules/<module>/PLAN.md`: only file written by agent `<module>-plan`.
