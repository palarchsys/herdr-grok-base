# Regle projet. Un fichier = un ajout. Ne pas modifier AGENTS.md.

Nom : `regles/AGENT-<n>-<NOM>.md`.
`n` = 0, 1, 2… Ordre de lecture = ordre de `n`.
`NOM` = `[A-Z0-9-]{1,16}`.

```
n: 0
nom: SQL
applique: oui
corps: |
  <regle fermee>
```

`applique: non` = ne pas appliquer.
Pas de prose hors `corps`.
