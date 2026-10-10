key: impl-sync
hash: 860b92d9bc7b
llm: grok-build
role: impl
tech:
  - sync
sources:
  - configs/sources/impl-sync.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: sync. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
