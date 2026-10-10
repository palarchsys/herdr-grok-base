key: plan-upstream
hash: 18c4945d6500
llm: grok-build
role: plan
tech:
  - upstream
sources:
  - configs/sources/plan-upstream.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: upstream. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
