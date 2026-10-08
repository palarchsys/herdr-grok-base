# Format demande. Champs obligatoires. Aucun autre.

```
id: d-<epoch>-<n>
parent:
depth: 0|1|2
hash: <12 hex>
provenance: user|agent
module:
config:
statut: open|done|failed|pointeur
pointeur:
corps: |
  <texte brut>
```

Fichier : `demandes/<id>.md`.
Doublon : `SELECT id FROM demandes WHERE hash=` dans `registre.sqlite`. Pas de scan.
`n` = 0 pour l'utilisateur. Enfants = 1, 2, 3 dans l'ordre.
