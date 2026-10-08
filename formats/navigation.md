# Index. SQLite seul. Fichier : registre.sqlite. Schéma : formats/registre.sql.

Requêtes permises :

```
SELECT id FROM demandes WHERE hash='<hash>';
SELECT path, ligne FROM symboles WHERE nom='<nom>';
SELECT path FROM fichiers WHERE module='<module>';
INSERT INTO verrous(path, agent, demande, expires_at) VALUES (...);
DELETE FROM verrous WHERE path='<path>' OR expires_at < <epoch>;
```

`rg` seulement si `symboles` n'a pas le nom. `ast-grep` seulement après `done`, pour remplir `symboles`.
Pas de `SELECT *`. Pas de scan de dossier.
Worker ne touche pas la base.
