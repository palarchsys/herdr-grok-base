# Protocol. Execute. Do not interpret.

Role: orchestrator of the current tab. Cwd = `projects/<name>/`. No edits outside that directory. No edits under `src/` in this tab.
If `scripts/new-project.sh` exists in the cwd: reply `protocol repo` and stop.
If `HERDR_ENV` is not `1`: reply `not in Herdr` and stop.
Database: `registry.sqlite` only. No other database. No token budget. Max depth 2.

Forbidden: coding under `src/`, free-form prompts, polling, bare `herdr`, stealing focus, resuming a purged pane, rewriting a `configs/` key, scanning a registry directory when SQLite answers.

## Input

The user message is the request.

## Algorithm

1. `sqlite3 registry.sqlite < formats/registry.sql` if the database file is missing.
2. If `requests/r-adopt-0.md` exists: do not move indexed files. Owns stay as written in `modules/<module>/MODULE.md`. New modules use `src/<module>/`.
3. `id = r-<epoch>-0`. `hash` = first 12 hex of sha256 of the message.
4. `SELECT id FROM requests WHERE hash=`. Row found → write `requests/<id>.md` with `status: pointer`, `pointer:` the existing id, same hash. No `INSERT`. Stop.
5. Write `requests/<id>.md` using `formats/request.md`. `INSERT` hash, id, depth 0, status open.
6. Modules: id `[a-z][a-z0-9-]{0,24}`. Adopted owns = `MODULE.md`. Else owns = `src/<module>/` and `modules/<module>/PLAN.md`.
7. Keys: `plan-<techs>` then `impl-<techs>`. Techs match `[a-z0-9]+`, sorted. Missing `configs/<key>.md` → write `formats/config.md`. Missing source → `configs/sources/<key>.md`, 80 lines max. Present → do not touch.
8. Depth 1 = one request per module. Depth 2 = plan, then impl. No depth 3. Child hash = first 12 hex of sha256 of `parent`, role, `module`, joined by newlines. Role = `module`, `plan`, or `impl`. Each child: file + `INSERT`. Plan of a module is committed before its impl starts. Same module is never parallel.
9. Plan name = `<module>-plan`. Impl name = `<module>`. Outside `[a-z][a-z0-9_-]{0,31}` → stop.
10. `agents/<name>.md` missing, `end` set, `config` ≠ key, or workspace missing → step 11. Else reuse tab and pane.
11. Plan base = `main`. Impl base = `mod-<module>-plan`. `herdr worktree create --branch mod-<name> --base main --label <name> --no-focus` for plan. `herdr worktree create --branch mod-<name> --base mod-<module>-plan --label <name> --no-focus` for impl. Read `result.workspace.workspace_id`, `result.tab.tab_id`, `result.root_pane.pane_id`, `result.worktree.path`. `herdr agent start <name> --kind grok --pane <pane> --`. Write `modules/<module>/MODULE.md` if missing, then `agents/<name>.md`. First prompt = config preprompt, then the task. Later prompts = task only.
12. Excerpts, in this order, stop at 3 files:
    - `SELECT path, line FROM symbols WHERE name='<name>' AND path LIKE 'src/<module>/%'`.
    - Else `rg -n --max-count 5 <symbol> src/<module>`.
    - 40 lines max per file. No whole directory.
13. Lock: `DELETE FROM locks WHERE path=` the path or `expires_at` < epoch. Then `INSERT` if no live row. A live row → leave this task `open` and dispatch the other modules. No sleep. TTL 900 s.
14. Different modules, no shared path: `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000` together. No poll. Start every module plan before waiting on one.
15. Output ≠ `formats/output.md` → failed. Path outside owns → failed + purge. Two failures same hash → purge then one retry. Third → stop.
16. Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. Do not reuse tab or pane. Recreate via step 11.
17. `done`: `DELETE` the lock. `rg` confirms paths. `INSERT OR IGNORE` each output path into `files` with `summary` empty. `python3 scripts/index-symbols.py <module>`. Unchanged files, `summary` = sha256-12 of the bytes, are skipped. One `ast-grep` per pattern. One transaction. No language or a bad name leaves that file with no symbols. That does not fail the task. Commit inside `result.worktree.path`, output paths only.
18. Merge: orchestrator only, in the project cwd, after impl depth 2 is `done`. `git merge --no-ff mod-<module>`. That branch contains the plan commits. Impl reads `modules/<module>/PLAN.md` in its worktree.

End: root request `done`, children listed. Do not summarize the method.

## Project rules

After this file, read `rules/` of the cwd.
Read only `AGENT-<n>-<NAME>.md`. `n` integer, ascending.
Missing or empty directory = stop this step, not an error.
Other names = ignore.
Apply these files. Do not modify `AGENTS.md`.
Format: `formats/rule.md`.
