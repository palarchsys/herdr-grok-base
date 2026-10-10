# Config format. Immutable.

```
key: <key>
hash: <12 hex>
llm: grok-build
role: plan|impl
tech:
  - <tech>
sources:
  - configs/sources/<key>.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: <tech>. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
```

File: `configs/<key>.md`.
`key` = `plan` or `impl`, then sorted techs. `plan-vue`, `impl-vue`.
Tech names match `[a-z0-9]+`.
Present = reuse. A second file is forbidden.
Source: `configs/sources/<key>.md`, 80 lines max, written once.
Preprompt sent once, on the agent first prompt. Never again.
