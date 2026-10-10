key: plan-report
hash: 4ee06502f6ea
llm: grok-build
role: plan
tech:
  - report
sources:
  - configs/sources/plan-report.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: report. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
