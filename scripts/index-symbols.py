#!/usr/bin/env python3
"""Index one module. One ast-grep run per pattern. One SQLite transaction.

Skips a file when files.summary is already the first 12 hex of sha256(bytes).
Does not hash a file above 1 Mio. ast-grep receives the changed files, not
their parent directory. Bash uses function_definition nodes, not a $NAME pattern.
"""
import hashlib
import json
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
BASH_FN_RE = re.compile(r"^(?:function[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)")
SCRIPT_RE = re.compile(r"<script\b([^>]*)>(.*?)</script>", re.IGNORECASE | re.DOTALL)
LANG_ATTR_RE = re.compile(r"""lang\s*=\s*['"]?([A-Za-z]+)""")
MAX_BYTES = 1024 * 1024


def parse_symbols(text):
    current = None
    pending_kind = None
    found = []
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("ext: "):
            current = {"ext": line.split(": ", 1)[1].strip(), "lang": "", "patterns": []}
            found.append(current)
            pending_kind = None
        elif current is not None and line.startswith("lang: "):
            current["lang"] = line.split(": ", 1)[1].strip()
        elif current is not None and line.startswith("- kind:"):
            pending_kind = line.split(":", 1)[1].strip()
        elif current is not None and pending_kind and line.startswith("pattern:"):
            current["patterns"].append((pending_kind, line.split(":", 1)[1].strip()))
            pending_kind = None
    return {
        item["ext"]: item
        for item in found
        if item["lang"] and item["patterns"]
    }


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def script_ast_lang(attrs):
    match = LANG_ATTR_RE.search(attrs or "")
    if match and match.group(1).lower() in {"js", "javascript"}:
        return "js"
    return "ts"


def vue_scripts(text):
    blocks = []
    for match in SCRIPT_RE.finditer(text):
        start = text[: match.start(2)].count("\n")
        padded = ("\n" * start) + match.group(2)
        blocks.append((script_ast_lang(match.group(1)), padded))
    return blocks


def load_matches(stdout):
    if not stdout.strip():
        return []
    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return data


def matches(lang, pattern, paths):
    if not paths:
        return []
    proc = subprocess.run(
        ["ast-grep", "run", "-l", lang, "-p", pattern, "--json", *[str(p) for p in paths]],
        capture_output=True,
        text=True,
    )
    return load_matches(proc.stdout)


def bash_matches(paths):
    if not paths:
        return []
    found = []
    for start in range(0, len(paths), 100):
        chunk = paths[start : start + 100]
        proc = subprocess.run(
            [
                "ast-grep",
                "run",
                "-l",
                "bash",
                "--kind",
                "function_definition",
                "--json",
                *[str(p) for p in chunk],
            ],
            capture_output=True,
            text=True,
        )
        found.extend(load_matches(proc.stdout))
    return found


def matches_stdin(lang, pattern, source):
    proc = subprocess.run(
        ["ast-grep", "run", "-l", lang, "-p", pattern, "--json", "--stdin"],
        input=source,
        capture_output=True,
        text=True,
    )
    return load_matches(proc.stdout)


def symbol_name(match):
    name = (
        (match.get("metaVariables") or {})
        .get("single", {})
        .get("NAME", {})
        .get("text")
    )
    line0 = (match.get("range") or {}).get("start", {}).get("line")
    if not name or line0 is None or not NAME_RE.match(name):
        return None
    return name, line0 + 1


def bash_symbol_name(match):
    text = match.get("text") or ""
    line0 = (match.get("range") or {}).get("start", {}).get("line")
    found = BASH_FN_RE.match(text)
    if not found or line0 is None:
        return None
    name = found.group(1)
    if not NAME_RE.match(name):
        return None
    return name, line0 + 1


def main():
    if len(sys.argv) != 2:
        print("usage: index-symbols.py <module>", file=sys.stderr)
        return 2
    module = sys.argv[1]
    root = Path.cwd()
    db_path = root / "registry.sqlite"
    spec_path = root / "formats" / "symbols.md"
    if not db_path.is_file() or not spec_path.is_file():
        print("registry.sqlite or formats/symbols.md missing", file=sys.stderr)
        return 1
    by_ext = parse_symbols(spec_path.read_text())
    db = sqlite3.connect(db_path)
    rows = db.execute(
        "SELECT path, summary FROM files WHERE module=?",
        (module,),
    ).fetchall()
    changed = []
    hashes = {}
    for rel, summary in rows:
        file = root / rel
        if not file.is_file():
            continue
        try:
            if file.stat().st_size > MAX_BYTES:
                continue
        except OSError:
            continue
        file_hash = digest(file)
        hashes[rel] = file_hash
        if summary != file_hash:
            changed.append(rel)
    if not changed:
        return 0

    wanted = set(changed)
    by_ext_files = {}
    vue_rels = []
    bash_rels = []
    for rel in changed:
        ext = Path(rel).suffix.lower().lstrip(".")
        spec = by_ext.get(ext)
        if spec is None:
            continue
        if spec["lang"] == "bash":
            bash_rels.append(rel)
            continue
        if ext == "vue" or spec["lang"] == "script":
            vue_rels.append(rel)
            continue
        by_ext_files.setdefault(ext, []).append(rel)

    inserts = []
    seen = set()
    root_resolved = root.resolve()

    def add_hit(rel, kind, found):
        if found is None or rel not in wanted:
            return
        name, line = found
        key = (rel, name, kind, line)
        if key in seen:
            return
        seen.add(key)
        inserts.append(key)

    def rel_of(match):
        raw_file = match.get("file") or ""
        try:
            return str(Path(raw_file).resolve().relative_to(root_resolved))
        except ValueError:
            return None

    for ext, rels in by_ext_files.items():
        spec = by_ext[ext]
        files = [root / rel for rel in rels]
        for kind, pattern in spec["patterns"]:
            for match in matches(spec["lang"], pattern, files):
                rel = rel_of(match)
                if rel is None:
                    continue
                add_hit(rel, kind, symbol_name(match))

    if bash_rels:
        bash_spec = by_ext.get(Path(bash_rels[0]).suffix.lower().lstrip("."))
        kind = "function"
        if bash_spec and bash_spec["patterns"]:
            kind = bash_spec["patterns"][0][0]
        files = [root / rel for rel in bash_rels]
        for match in bash_matches(files):
            rel = rel_of(match)
            if rel is None:
                continue
            add_hit(rel, kind, bash_symbol_name(match))

    vue_spec = by_ext.get("vue")
    if vue_spec:
        for rel in vue_rels:
            text = (root / rel).read_text(encoding="utf-8", errors="replace")
            for ast_lang, padded in vue_scripts(text):
                for kind, pattern in vue_spec["patterns"]:
                    for match in matches_stdin(ast_lang, pattern, padded):
                        add_hit(rel, kind, symbol_name(match))

    with db:
        for rel in changed:
            db.execute("DELETE FROM symbols WHERE path=?", (rel,))
            db.execute(
                "UPDATE files SET summary=? WHERE path=?",
                (hashes[rel], rel),
            )
        db.executemany(
            "INSERT OR REPLACE INTO symbols(path, name, kind, line) VALUES (?, ?, ?, ?)",
            inserts,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
