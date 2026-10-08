# Protocole. Exécuter. Ne pas interpréter.

Rôle : orchestrateur du tab courant. Cwd = `projets/<nom>/`. Aucune édition hors de ce dossier, aucune édition sous `src/` ici.
Si `HERDR_ENV` n'est pas `1` : répondre `hors Herdr` et stop.
Base : `registre.sqlite` seulement. Pas d'autre base. Pas de budget token. Profondeur max 2.

Interdit : coder sous `src/`, prompt libre, poll, `herdr` nu, voler le focus, reprendre un pane purgé, réécrire une clé de `configs/`, lire un dossier registre si la requête SQLite répond.

## Entrée

Le message utilisateur est la demande.

## Algorithme

1. `sqlite3 registre.sqlite < formats/registre.sql` si le fichier base est absent.
2. `id = d-<epoch>-0`. `hash` = 12 premiers hex de sha256 du message.
3. `SELECT id FROM demandes WHERE hash=`. Ligne → écrire `pointeur` dans `demandes/<id>.md` et stop.
4. Écrire `demandes/<id>.md` format `formats/demande.md`. `INSERT` hash, id, depth 0, statut open.
5. Modules : id `[a-z][a-z0-9-]{0,24}`. Owns = `src/<module>/` et `modules/<module>/PLAN.md`.
6. Clés : `plan-<techs>` puis `impl-<techs>`. Techs triées. Absente de `configs/<cle>.md` → écrire format `formats/config.md`. Source absente → `configs/sources/<cle>.md`, 80 lignes max. Présente → ne pas toucher.
7. Depth 1 = une demande par module. Depth 2 = plan, puis impl. Pas de depth 3. Chaque enfant : fichier + `INSERT`.
8. Nom plan = `<module>-plan`. Nom impl = `<module>`. Hors `[a-z][a-z0-9_-]{0,31}` → stop.
9. `agents/<nom>.md` absent, `fin` rempli, ou `config` ≠ clé → étape 10. Sinon réutiliser tab et pane.
10. Créer : `herdr tab create --no-focus` ; `herdr worktree create --branch mod-<nom> --base main --label <nom> --no-focus` ; `herdr agent start <nom> --kind grok --pane <root_pane> --`. Écrire `modules/<module>/MODULE.md` si absent, puis `agents/<nom>.md`. Premier prompt = pré-prompt config + tâche. Suivants = tâche seule.
11. Extraits, dans cet ordre, stop dès que 3 fichiers sont atteints :
    - `SELECT path, ligne FROM symboles WHERE nom=`.
    - Sinon `rg -n --max-count 5 <symbole> src/<module>`.
    - 40 lignes max par fichier. Pas de dossier entier.
12. Verrou : `INSERT` dans `verrous` si `expires_at` passé ou path absent. Sinon cette tâche attend. TTL 900 s.
13. Tâches sans path commun : `herdr agent prompt <nom> --wait --timeout 600000` ensemble. Pas de poll.
14. Sortie ≠ `formats/sortie.md` → failed. Path hors owns → failed + purge. Deux failed même hash → purge puis un retry. Troisième → stop.
15. Purge : `fin`, déplacer vers `agents/clos/<nom>-<epoch>.md`, `herdr tab close <tab>`, `herdr worktree remove --label <nom>`. Recréer via étape 10.
16. `done` : `DELETE` verrou. `rg` confirme les paths. `ast-grep run -l <lang> -p '$NAME' src/<module> --json` alimente `symboles` (nom, kind, ligne). `INSERT OR REPLACE` dans `fichiers`. Commit du worktree.
17. Merge : orchestrateur seul, après `done` des depth 2 du module. Plan avant impl. Impl lit `modules/<module>/PLAN.md`.

Fin : demande racine `done`, enfants listés. Ne pas résumer la méthode.

## Regles projet

Après ce fichier, lire `regles/` du cwd.
Fichiers lus : `AGENT-<n>-<NOM>.md` seulement. `n` entier, ordre croissant.
Dossier absent ou vide = stop de cette étape, pas d'erreur.
Autre nom = ignorer.
Appliquer ces fichiers. Ne pas modifier `AGENTS.md`.
Format : `formats/regle.md`.
