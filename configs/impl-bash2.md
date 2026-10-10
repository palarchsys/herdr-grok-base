key: impl-bash2
hash: 12752963cfb3
llm: grok-build
role: impl
tech:
  - bash2
sources:
  - configs/sources/impl-bash2.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: bash2. The source is syntax, 80 lines.
  Laws and rules/AGENT-*.md in the prompt are the project policy.
  Write only under owns.
  The status/files/config block is the last block. Prose above it is ignored.
