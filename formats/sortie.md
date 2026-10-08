# Sortie worker. Seul texte accepté.

```
statut: done|failed
fichiers:
  - <path>
config: <cle>
```

Autre texte = `failed`.
`done` seulement si chaque path est sous `owns`.
Agent plan : seul path permis `modules/<module>/PLAN.md`.
Orchestrateur copie ce bloc en bas de `demandes/<id>.md`.
