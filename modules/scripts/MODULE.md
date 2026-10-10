id: scripts
owns:
  - src/scripts/**
  - src/AGENTS.md
  - src/formats/**
  - src/README.md
  - modules/scripts/PLAN.md
laws: []
imports: []
events_in: []
events_out: []
check: bash src/scripts/check.sh
publish:
git: parent
split:
forbidden:
  - write outside owns
  - read requests, agents, locks, or the database
  - call an agent
  - open a tab
