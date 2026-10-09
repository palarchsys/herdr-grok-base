#!/usr/bin/env python3
"""Index one module. One ast-grep run per pattern. One SQLite transaction.

Skips a file when files.summary is already the first 12 hex of sha256(bytes).
"""
import hashlib
import json
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


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


def matches(lang, pattern, directory):
    proc = subprocess.run(
        ["ast-grep", "run", "-l", lang, "-p", pattern, "--json", str(directory)],
        capture_output=True,
        text=True,
    )
    if not proc.stdout.strip():
        return []
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return data


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
        file_hash = digest(file)
        hashes[rel] = file_hash
        if summary != file_hash:
            changed.append(rel)
    if not changed:
        return 0

    wanted = set(changed)
    by_dir = {}
    for rel in changed:
        ext = Path(rel).suffix.lower().lstrip(".")
        if ext not in by_ext:
            continue
        parent = str(Path(rel).parent)
        by_dir.setdefault((ext, parent), []).append(rel)

    inserts = []
    seen = set()
    root_resolved = root.resolve()
    for (ext, parent), _paths in by_dir.items():
        spec = by_ext[ext]
        directory = root / parent
        if not directory.is_dir():
            continue
        for kind, pattern in spec["patterns"]:
            for match in matches(spec["lang"], pattern, directory):
                name = (
                    (match.get("metaVariables") or {})
                    .get("single", {})
                    .get("NAME", {})
                    .get("text")
                )
                if not name or not NAME_RE.match(name):
                    continue
                line0 = (match.get("range") or {}).get("start", {}).get("line")
                if line0 is None:
                    continue
                raw_file = match.get("file") or ""
                try:
                    rel = str(Path(raw_file).resolve().relative_to(root_resolved))
                except ValueError:
                    continue
                if rel not in wanted:
                    continue
                key = (rel, name, kind, line0 + 1)
                if key in seen:
                    continue
                seen.add(key)
                inserts.append(key)

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
    sys.exit(main())
