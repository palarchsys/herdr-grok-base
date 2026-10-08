# Request format. Required fields. No others.

```
id: r-<epoch>-<n>
parent:
depth: 0|1|2
hash: <12 hex>
origin: user|agent
module:
config:
status: open|done|failed|pointer
pointer:
body: |
  <raw text>
```

File: `requests/<id>.md`.
Duplicate: `SELECT id FROM requests WHERE hash=` in `registry.sqlite`. No scan.
`n` = 0 for the user. Children = 1, 2, 3 in order.
