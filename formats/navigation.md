# Index. SQLite only. File: registry.sqlite. Schema: formats/registry.sql.

Allowed queries:

```
SELECT id FROM requests WHERE hash='<hash>';
SELECT path, line FROM symbols WHERE name='<name>' AND path LIKE 'src/<module>/%';
SELECT path FROM files WHERE module='<module>';
INSERT INTO requests(hash, id, parent, depth, module, config, status) VALUES (...);
INSERT OR REPLACE INTO files(path, module, summary) VALUES (...);
DELETE FROM symbols WHERE path='<path>';
INSERT OR REPLACE INTO symbols(path, name, kind, line) VALUES (...);
DELETE FROM locks WHERE path='<path>' OR expires_at < <epoch>;
INSERT INTO locks(path, agent, request, expires_at) VALUES (...);
DELETE FROM locks WHERE path='<path>';
```

`DELETE` the lock row before `INSERT` when the path is free or expired.
`files.summary` = first 12 hex of sha256 of the file bytes. Empty = not indexed.
`rg` only if `symbols` has no name in the module. `python3 scripts/index-symbols.py <module>` after the merge, once, in the project cwd.
No `SELECT *`. No directory scan.
Worker does not touch the database.
