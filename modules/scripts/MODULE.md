id: scripts
owns:
  - src/scripts/**
  - src/README.md
  - modules/scripts/PLAN.md
exports: []
imports: []
events_in: []
events_out: []
forbidden:
  - write outside owns
  - read requests configs agents locks rules
  - call an agent
  - open a tab
