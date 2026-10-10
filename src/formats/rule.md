# Project rule. One file = one addition. Do not modify AGENTS.md.

Name: `rules/AGENT-<n>-<NAME>.md`.
`n` = 0, 1, 2… Read order = `n` order.
`NAME` = `[A-Z0-9-]{1,16}`.

```
n: 0
name: SQL
apply: yes
body: |
  <closed rule>
```

`apply: no` = do not apply.
No prose outside `body`.
