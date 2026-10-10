key: impl-bash
hash: 12c1ddb088df
llm: grok-build
role: impl
tech:
  - bash
sources:
  - configs/sources/impl-bash.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: bash. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
