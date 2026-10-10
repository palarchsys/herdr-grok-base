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
  Tech: <tech>. The source is syntax, 80 lines.
  Laws and rules/AGENT-*.md in the prompt are the project policy.
  Write only under owns.
  The status/files/config block is the last block. Prose above it is ignored.
```

File: `configs/<key>.md`.
`key` = `impl`, then sorted techs, for the single agent. `plan` only when `split: plan`. `impl-vue`, `plan-vue`.
Tech names match `[a-z0-9]+`.
Present = reuse. A second file is forbidden.
Source: `configs/sources/<key>.md`, 80 lines max, written once.
`hash` = first 12 hex of sha256 of that source.
Preprompt sent once, on the agent first prompt. Never again.
