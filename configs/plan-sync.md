key: plan-sync
hash: 5b37b988f189
llm: grok-build
role: plan
tech:
  - sync
sources:
  - configs/sources/plan-sync.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: sync. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
