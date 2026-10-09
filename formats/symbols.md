# Symbol patterns. ast-grep. `$NAME` is the identifier.

Store `metaVariables.single.NAME.text` and `range.start.line` + 1.
Store the name only when it matches `^[A-Za-z_][A-Za-z0-9_]*$`.
`kind` is the label below.
No `lang` for the extension → do not call ast-grep.
`DELETE FROM symbols WHERE path=` that file, then insert the matches.
Empty matches leave that file with no symbols.

```
ext: js
lang: js
patterns:
  - kind: function
    pattern: function $NAME($$$A) { $$$B }
  - kind: class
    pattern: class $NAME { $$$B }
  - kind: const
    pattern: const $NAME = ($$$A) => $B
  - kind: const
    pattern: const $NAME = ($$$A) => { $$$B }

ext: ts
lang: ts
patterns:
  - kind: function
    pattern: function $NAME($$$A) { $$$B }
  - kind: class
    pattern: class $NAME { $$$B }
  - kind: const
    pattern: const $NAME = ($$$A) => $B
  - kind: const
    pattern: const $NAME = ($$$A) => { $$$B }

ext: vue
lang: script
patterns:
  - kind: function
    pattern: function $NAME($$$A) { $$$B }
  - kind: class
    pattern: class $NAME { $$$B }
  - kind: const
    pattern: const $NAME = ($$$A) => $B
  - kind: const
    pattern: const $NAME = ($$$A) => { $$$B }

ext: py
lang: py
patterns:
  - kind: function
    pattern: def $NAME($$$A): $$$B
  - kind: class
    pattern: class $NAME: $$$B

ext: go
lang: go
patterns:
  - kind: function
    pattern: func $NAME($$$A) $R { $$$B }
  - kind: struct
    pattern: type $NAME struct { $$$B }

ext: rs
lang: rust
patterns:
  - kind: function
    pattern: fn $NAME($$$A) -> $R { $$$B }
  - kind: function
    pattern: fn $NAME($$$A) { $$$B }
  - kind: struct
    pattern: struct $NAME { $$$B }
```

`.vue` uses `lang: script`. Each `<script>` block is read with ast-grep `--stdin`.
Missing `lang`, and `ts`, `tsx`, or `typescript`, use `ts`. Explicit `js` or `javascript` uses `js`.
The stored line is the line in the `.vue` file.
Command: `ast-grep run -l <lang> -p '<pattern>' <file> --json`.
