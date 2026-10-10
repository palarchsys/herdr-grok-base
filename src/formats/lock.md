# Lock format. Table `locks` in registry.sqlite. No file.

```
path, agent, request, expires_at
```

`expires_at` = epoch + 900.
Path present and not expired = do not dispatch.
Expired = `DELETE`, then `INSERT`.
Never copied into a prompt.
