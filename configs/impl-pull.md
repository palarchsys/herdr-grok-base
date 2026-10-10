key: impl-pull
hash: 793c7f446ba0
llm: grok-build
role: impl
tech:
  - pull
sources:
  - configs/sources/impl-pull.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: pull. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
