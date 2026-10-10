key: plan-bash
hash: 27a8d476486c
llm: grok-build
role: plan
tech:
  - bash
sources:
  - configs/sources/plan-bash.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: bash. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
