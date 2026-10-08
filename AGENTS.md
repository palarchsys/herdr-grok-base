# Protocol. Execute. Do not interpret.

Role: orchestrator of the current tab. Cwd = `projects/<name>/`. No edits outside that directory. No edits under `src/` in this tab.
If `HERDR_ENV` is not `1`: reply `not in Herdr` and stop.
Database: `registry.sqlite` only. No other database. No token budget. Max depth 2.

Forbidden: coding under `src/`, free-form prompts, polling, bare `herdr`, stealing focus, resuming a purged pane, rewriting a `configs/` key, scanning a registry directory when SQLite answers.

## Input

The user message is the request.

## Algorithm

1. `sqlite3 registry.sqlite < formats/registry.sql` if the database file is missing.
2. If `requests/r-adopt-0.md` exists: do not move indexed files. Owns stay as written in `modules/<module>/MODULE.md`. New modules use `src/<module>/`.
3. `id = r-<epoch>-0`. `hash` = first 12 hex of sha256 of the message.
4. `SELECT id FROM requests WHERE hash=`. Row found → write `pointer` in `requests/<id>.md` and stop.
5. Write `requests/<id>.md` using `formats/request.md`. `INSERT` hash, id, depth 0, status open.
6. Modules: id `[a-z][a-z0-9-]{0,24}`. Adopted owns = `MODULE.md`. Else owns = `src/<module>/` and `modules/<module>/PLAN.md`.
7. Keys: `plan-<techs>` then `impl-<techs>`. Techs sorted. Missing `configs/<key>.md` → write `formats/config.md`. Missing source → `configs/sources/<key>.md`, 80 lines max. Present → do not touch.
8. Depth 1 = one request per module. Depth 2 = plan, then impl. No depth 3. Each child: file + `INSERT`.
9. Plan name = `<module>-plan`. Impl name = `<module>`. Outside `[a-z][a-z0-9_-]{0,31}` → stop.
10. `agents/<name>.md` missing, `end` set, or `config` ≠ key → step 11. Else reuse tab and pane.
11. Create: `herdr tab create --no-focus`; `herdr worktree create --branch mod-<name> --base main --label <name> --no-focus`; `herdr agent start <name> --kind grok --pane <root_pane> --`. Write `modules/<module>/MODULE.md` if missing, then `agents/<name>.md`. First prompt = config preprompt + task. Later prompts = task only.
12. Excerpts, in this order, stop at 3 files:
    - `SELECT path, line FROM symbols WHERE name=`.
    - Else `rg -n --max-count 5 <symbol> src/<module>`.
    - 40 lines max per file. No whole directory.
13. Lock: `INSERT` into `locks` if `expires_at` passed or path missing. Else this task waits. TTL 900 s.
14. Tasks with no shared path: `herdr agent prompt <name> --wait --timeout 600000` together. No poll.
15. Output ≠ `formats/output.md` → failed. Path outside owns → failed + purge. Two failures same hash → purge then one retry. Third → stop.
16. Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr tab close <tab>`, `herdr worktree remove --label <name>`. Recreate via step 11.
17. `done`: `DELETE` lock. `rg` confirms paths. `ast-grep run -l <lang> -p '$NAME' src/<module> --json` fills `symbols` (name, kind, line). `INSERT OR REPLACE` into `files`. Commit the worktree.
18. Merge: orchestrator only, after all depth 2 of the module are `done`. Plan before impl. Impl reads `modules/<module>/PLAN.md`.

End: root request `done`, children listed. Do not summarize the method.

## Project rules

After this file, read `rules/` of the cwd.
Read only `AGENT-<n>-<NAME>.md`. `n` integer, ascending.
Missing or empty directory = stop this step, not an error.
Other names = ignore.
Apply these files. Do not modify `AGENTS.md`.
Format: `formats/rule.md`.
