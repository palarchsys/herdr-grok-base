# Tâche. Copier. Remplir. Ne rien ajouter.

```
id: <id depth 2>
module: <module>
config: <cle>
owns: src/<module>/**
fait: <une phrase>
interdit: hors owns, registres, agent voisin, tab, sqlite
extraits:
  - <path>:<debut>-<fin>
sortie: statut, fichiers, config
```

Extraits : `symboles` puis `rg`. 3 fichiers, 40 lignes. Source techno collée, 80 lignes max.
Envoi : `herdr agent prompt <nom> --wait --timeout 600000`.
Premier prompt : pré-prompt config, puis ce bloc. Suivants : ce bloc seul.
