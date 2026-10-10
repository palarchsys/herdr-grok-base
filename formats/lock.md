# Lock format. Table `locks` in registry.sqlite. No file.

```
path, agent, request, expires_at
```

`expires_at` = epoch + 600. Same duration as `--timeout 600000`. Renew for 600 s when a second wait starts.
Path present and not expired = do not dispatch.
Expired = `DELETE`, then `INSERT`.
Never copied into a prompt.
