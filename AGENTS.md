# Protocol. Execute. Do not interpret.

Role: orchestrator of the current tab. Cwd = `projects/<name>/`. No edits outside that directory. No edits under `src/` in this tab.
If `scripts/new-project.sh` exists in the cwd: reply `protocol repo` and stop.
If `HERDR_ENV` is not `1`: reply `not in Herdr` and stop.
Database: `registry.sqlite` only. No other database. No token budget. Max depth 2.

Forbidden: coding under `src/`, free-form prompts, polling, bare `herdr`, stealing focus, resuming a purged pane, rewriting a `configs/` key, scanning a registry directory when SQLite answers.

## Input

0. Class of the message.
    - `ask` — question, critique, review, or explanation. Answer in this tab. No `requests/` file, no agent, no worktree, no hash.
    - `git` — commit or push already decided. The comment is in the message. Orchestrator only. No agent. `publish:` empty: `git add` the owns, `git commit` with that comment, `git push` in the project repository. `publish:` set: run that command with the comment. Do not invent a second publish path.
    - `edit` — the sentence names a file change. Steps 3 to 18 apply only to an `edit`.

Mode guard, for `git` and `edit`, before step 3. In the project repository, and in each nested repository the message names: read `git diff --numstat` and `git diff --cached --numstat`. A line with `=>` or a non-zero count is content. Leave it. When every line is `0` and `0` with no `=>`, and HEAD exists: `git restore --source=HEAD --worktree --staged -- .`. If a `0`/`0` line remains: `git config core.fileMode false` in that repository. Read the status again. No content diff does not open a module. `ask` skips this guard.

The user message is the request only when the class is `edit`.

## Algorithm

1. `sqlite3 registry.sqlite < formats/registry.sql` if the database file is missing.
2. If `requests/r-adopt-0.md` exists: do not move indexed files. Owns stay as written in `modules/<module>/MODULE.md`. New modules use `src/<module>/`.
3. `id = r-<epoch>-0`. `hash` = first 12 hex of sha256 of the message.
4. Pointer only for an `edit` whose hash already has a module child. `SELECT id FROM requests WHERE hash=`. Row found → write `requests/<id>.md` with `status: pointer`, `pointer:` the existing id, same hash. No `INSERT`. Stop. An `ask` is not stored.
5. Write `requests/<id>.md` using `formats/request.md`. `INSERT` hash, id, depth 0, status open.
6. Modules: id `[a-z][a-z0-9-]{0,24}`. Adopted owns = `MODULE.md`. Else owns = `src/<module>/` and `modules/<module>/PLAN.md`. Split the request by independent concern: graphics, database, ux, core, or another disjoint area. Disjoint owns inside one concern are several modules. Overlapping files stay one module. No module that writes nothing. Owns do not overlap.
7. One key `impl-<techs>` for the agent. `plan-<techs>` only when `MODULE.md` contains `split: plan`. Techs match `[a-z0-9]+`, sorted. Missing `configs/<key>.md` → write `formats/config.md`. Missing source → `configs/sources/<key>.md`, 80 lines max. Present → do not touch.
8. Depth 1 = one request per module. Depth 2 = one impl request. `split: plan` adds a plan request. That plan is committed before its impl starts. No depth 3. Child hash = first 12 hex of sha256 of `parent`, role, `module`, joined by newlines. Role = `module`, `plan`, or `impl`. Each child: file + `INSERT`. One agent per module. Same module is never parallel. Modules of one concern run together. Agent count equals the ready modules.
9. Name = `<module>`. `split: plan`: plan name = `<module>-plan`, impl name = `<module>`. Outside `[a-z][a-z0-9_-]{0,31}` → stop.
10. `agents/<name>.md` missing, `end` set, `config` ≠ key, or workspace missing → step 11. Else reuse tab and pane.
11. Default: one branch `mod-<module>`, one worktree, one process. `herdr worktree create --branch mod-<name> --base main --label <name> --no-focus`. If branch `mod-<module>` exists and is contained in `main`, the worktree starts at `main` and the branch advances. If that branch has commits that are not in `main`, stop. `split: plan`: plan base = `main`, then `herdr worktree create --branch mod-<name> --base mod-<module>-plan --label <name> --no-focus` for impl. `git: nested`: `herdr worktree create --cwd <repo> --branch mod-<name> --base <current branch> --label <name> --no-focus`. The commit is in that repository. Read `result.workspace.workspace_id`, `result.tab.tab_id`, `result.root_pane.pane_id`, `result.worktree.path`. `herdr agent start <name> --kind grok --pane <pane> --`. Write `modules/<module>/MODULE.md` if missing, then `agents/<name>.md`. First prompt = config preprompt, each `laws:` file in full, each `rules/AGENT-*.md` in full, then the task. A file the task edits, under 200 lines, is pasted in full. Later prompts = the task, plus the error on a retry.
12. Excerpts, in this order, stop at 3 files:
    - `SELECT path, line FROM symbols WHERE name='<name>' AND path LIKE 'src/<module>/%'`.
    - Else `rg -n --max-count 5 <symbol> src/<module>`.
    - 40 lines max per file. No whole directory.
    - Paths in `laws:` do not count. The pasted file under 200 lines does not count.
13. Lock: `DELETE FROM locks WHERE path=` the path or `expires_at` < epoch. Then `INSERT` if no live row. A live row → leave this task `open` and dispatch the other modules. No sleep. TTL 600 s, the same duration as `--timeout 600000`. Renew it for 600 s when a second wait starts.
14. Performance: wall time is the slowest ready module, not the sum. Empty `imports` and no shared path: start together. `imports`: start after each named module is merged. The prompt receives at most 50 file names from each imported module. Keep paths that contain a path named in the task, sorted. If none match, keep the first 50 paths, sorted. End with `<n> more` when names were left out. `git: nested`: `git -C <repo> ls-files`. `git: parent`: paths in `files` for that module. No tree. Start every ready prompt in the background: `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000 &`. Do not run the next prompt only after `--wait` returns. No poll. `wait -n` returns when the next agent exits. `split: plan`: Do not wait for every plan before any impl. Close that committed plan, then start its impl prompt in the background while other modules still run. A live lock leaves that task open. The other modules keep running. A prompt that returns on timeout gets one second prompt in the same pane and the same worktree: the task, plus `Continue. The first wait timed out.` Renew the lock. If that submission is rejected because the agent is still working, one `herdr agent wait <name> --until idle --until done --timeout 600000` instead of a third prompt. If the second wait also times out, or the agent is dead: set that module `failed`, `DELETE` the lock, close the worktree as in step 16, and say so in this tab. Do not leave the request open. Do not start a third prompt.
15. The status/files/config block is the last block. Prose above it is ignored. Fail if a path is outside owns, an announced file is missing, or `check` fails. First failure: same pane, same worktree, send the error. Purge when the agent is dead or a path is outside owns.
16. Purge: set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. Do not reuse tab or pane. Recreate via step 11.
17. `done`: `DELETE` the lock. `rg` confirms paths. `INSERT OR IGNORE` each output path into `files` with `summary` empty. Commit inside `result.worktree.path`, output paths only. One commit. `git: parent` commits in the project repository. `git: nested` commits in that repository. `modules/<module>/PLAN.md` is part of the same commit when it lives in the parent. Then set `end`, move to `agents/closed/<name>-<epoch>.md`, `herdr worktree remove --workspace <workspace> --force`. That closes that worker workspace, its tab, and its pane. The git branch stays. Do not close the orchestrator tab. Workspace already gone: `git worktree remove` the checkout. Untracked files after that commit: `git worktree remove --force` that path. Do not reuse that tab or pane.
18. Merge: orchestrator only, in the project cwd, after the checkout is removed. One branch at a time. A merge does not delay a module that does not import this one. `git: parent`: `git merge --no-ff mod-<module>`. That branch remains. `git: nested`: do not merge those paths into the parent. After the merge, `python3 scripts/index-symbols.py <module>` once, in the project cwd. Do not index before the next ready module starts. One `ast-grep` per pattern, on the changed files, not on their directory. One transaction. No language or a bad name leaves that file with no symbols. That does not fail the task. Unchanged files, `summary` = sha256-12 of the bytes, are skipped. A file above 1 Mio is not hashed.

`check:` empty: run nothing. `check:` set: run that command in the worktree after the commit, before the merge. Failure: the last 40 lines go back to the same agent, once. Not a new module.

End of an `edit` that changed files, three lines: files touched, the verification command, what was not run. Then say whether the product READMEs are current, or that this change has none. Ask whether to push, and the exact comment. Do not push in this turn. A worker does not ask. `scripts/update.sh` and `scripts/check.sh` print which projects changed. They ask nothing.

End: root request `done`, children listed. Do not summarize the method.

## Project rules

After this file, read `rules/` of the cwd.
Read only `AGENT-<n>-<NAME>.md`. `n` integer, ascending.
Missing or empty directory = stop this step, not an error.
Other names = ignore.
Apply these files. Do not modify `AGENTS.md`.
Format: `formats/rule.md`.
