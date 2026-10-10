key: plan-pull
hash: 927a0c82e255
llm: grok-build
role: plan
tech:
  - pull
sources:
  - configs/sources/plan-pull.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: pull. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
