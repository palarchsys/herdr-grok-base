key: impl-upstream
hash: 36861b7fd209
llm: grok-build
role: impl
tech:
  - upstream
sources:
  - configs/sources/impl-upstream.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: upstream. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
