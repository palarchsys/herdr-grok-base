# Format verrou. Table `verrous` de registre.sqlite. Pas de fichier.

```
path, agent, demande, expires_at
```

`expires_at` = epoch + 900.
Path présent et non expiré = ne pas dispatcher.
Expiré = `DELETE`, puis `INSERT`.
Jamais copié dans un prompt.
