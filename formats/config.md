# Format config. Immuable.

```
cle: <cle>
hash: <12 hex>
llm: grok-build
role: plan|impl
tech:
  - <tech>
sources:
  - configs/sources/<cle>.md
preprompt: |
  Exécuter la tâche. Ne pas modifier la méthode.
  Techno : <tech>. S'en tenir à la source, 80 lignes.
  Écrire seulement sous owns.
  Sortie = le bloc statut/fichiers/config, rien d'autre.
```

Fichier : `configs/<cle>.md`.
`cle` = `plan` ou `impl`, puis techs triées. `plan-vue`, `impl-vue`.
Présent = réutiliser. Second fichier interdit.
Source : `configs/sources/<cle>.md`, 80 lignes max, écrite une fois.
Pré-prompt envoyé une fois, au premier prompt de l'agent. Jamais après.
