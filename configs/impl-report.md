key: impl-report
hash: 8b4643482661
llm: grok-build
role: impl
tech:
  - report
sources:
  - configs/sources/impl-report.md
preprompt: |
  Execute the task. Do not change the method.
  Tech: report. Stay within the source, 80 lines.
  Write only under owns.
  Output = the status/files/config block, nothing else.
