# Format agent.

```
nom: <nom>
module: <module>
config: <cle>
llm: grok-build
tab: <id tab Herdr>
pane: <id pane Herdr>
worktree: <path rendu par herdr worktree create>
debut: <epoch>
fin:
```

Fichier vivant : `agents/<nom>.md`.
Purge : remplir `fin`, déplacer vers `agents/clos/<nom>-<epoch>.md`, ne pas réutiliser tab ni pane.
Nom impl = `<module>`. Nom plan = `<module>-plan`.
