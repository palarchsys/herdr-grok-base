# Format module.

```
id: <module>
owns:
  - src/<module>/**
  - modules/<module>/PLAN.md
exports: []
imports: []
events_in: []
events_out: []
forbidden:
  - ecrire hors owns
  - lire demandes configs agents verrous navigation
  - appeler un agent
  - ouvrir un tab
```

Fichier : `modules/<module>/MODULE.md`.
Id : `[a-z][a-z0-9-]{0,24}`.
Export modifié = depth 2 au propriétaire. Pas d'edit voisin.
`modules/<module>/PLAN.md` : seul fichier écrit par l'agent `<module>-plan`.
