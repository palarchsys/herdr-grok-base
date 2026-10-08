# Index. SQLite only. File: registry.sqlite. Schema: formats/registry.sql.

Allowed queries:

```
SELECT id FROM requests WHERE hash='<hash>';
SELECT path, line FROM symbols WHERE name='<name>';
SELECT path FROM files WHERE module='<module>';
INSERT INTO locks(path, agent, request, expires_at) VALUES (...);
DELETE FROM locks WHERE path='<path>' OR expires_at < <epoch>;
```

`rg` only if `symbols` has no name. `ast-grep` only after `done`, to fill `symbols`.
No `SELECT *`. No directory scan.
Worker does not touch the database.
