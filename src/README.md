# Forge orchestrateur

Grok ne lit pas ce README. Il lit `AGENTS.md` du projet lancé. `grok inspect` doit le lister.

La racine de ce dépôt est le protocole. Grok n'y écrit pas. Chemins, fichiers et commandes sont en anglais.

```
herdr-grok-base/
  AGENTS.md
  README.md
  formats/
  rules/
  projects/
    <name>/
      AGENTS.md
      formats/
      rules/
        AGENT-0-SQL.md
        AGENT-1-MD.md
      requests/
      configs/sources/
      agents/closed/
      modules/
      src/
      registry.sqlite
```

## Installation de base

Ubuntu 26.04 uniquement.

```bash
bash scripts/install.sh
```

Le script saute une étape déjà faite. Il n'écrit pas `config.toml`. Si `herdr integration status` ne montre pas `grok: current`, il installe le hook dans `~/.grok/hooks/`.

Sans droit root, `sqlite3`, `rg` et `ast-grep` sont installés dans `~/.local/bin`. `curl`, `unzip` et les certificats demandent encore root.

## Outils Ubuntu 26.04

Installés par le script s'ils manquent : `sqlite3`, `rg` (`ripgrep`), `ast-grep`.

`ast-grep` n'est pas dans apt. Le binaire Linux s'appelle `sg`. Le protocole appelle `ast-grep`.

Vérifier :

```bash
sqlite3 --version
rg --version
ast-grep --version
```

Les trois commandes doivent répondre. Sinon ne pas lancer de projet.

La base n'est pas créée ici. Elle l'est au lancement, depuis `formats/registry.sql`. Tables : `requests`, `files`, `symbols`, `locks`. `registry.sqlite` et ses journaux sont ignorés par git, à la racine et dans chaque projet créé.

## Nouveau projet

```bash
bash scripts/new-project.sh
```

`gh` est requis à côté de `git`, `sqlite3`, `rg` et `python3`. Le login vient de `gh api user --jq .login`. Un échec arrête le script.

Le dépôt existe lorsque `gh repo view <login>/<name> --json name` se termine par 0. Il est absent lorsque cette commande échoue et que la sortie contient `Could not resolve`. Tout autre échec arrête le script.

La question du nom et la question du dossier existant restent. La racine du protocole quitte avec le code 1 avant tout clone ou toute création de dépôt.

Si `projects/<name>` est absent et que le dépôt existe : `gh repo clone <login>/<name>` dans ce dossier. `AGENTS.md`, chaque fichier de `formats/` et `scripts/index-symbols.py` sont écrits depuis la racine du protocole, même s'ils existent déjà. Les autres entrées de la racine vont dans `src/<name>`. Les autres fichiers de `scripts/`, sauf `index-symbols.py`, vont dans `src/scripts/<name>`. Puis l'index.

Si `projects/<name>` est absent et que le dépôt est absent : `mkdir` de `projects`, puis `(cd projects && gh repo create <name> --private --clone)`, puis les mêmes fichiers du protocole. Ce clone vide n'a rien à déplacer et n'est pas indexé.

Si le dossier existe déjà : pas de clone. Les mêmes fichiers du protocole sont écrits, les entrées étrangères sont déplacées, puis l'index. Dépôt absent et `origin` absent : `gh repo create <name> --private --source <dest> --remote origin`. `origin` déjà présent : la même commande sans `--remote`. Jamais `--push`, jamais `--public`. Dépôt présent et `origin` absent : l'URL vient de `gh repo view <login>/<name> --json url --jq .url`, puis `git remote add origin <url>.git`. `origin` présent : on le laisse. `git init` seulement si `.git` manque.

Ne bougent jamais : `.git`, `.gitignore`, `AGENTS.md`, `formats`, `rules`, `requests`, `configs`, `agents`, `modules`, `src`, `scripts`, `registry.sqlite`, `registry.sqlite-journal`, `registry.sqlite-wal`, `registry.sqlite-shm`. Si `src/<name>` ou `src/scripts/<name>` existe déjà, le script affiche `left in place: <name>` et passe. Un chemin suivi par git est déplacé avec `git mv`. Sinon `mv`. Le déplacement a lieu après l'échafaudage et avant l'index. La racine du protocole quitte avec le code 1 avant `gh` : rien n'y est déplacé.

Un fichier de protocole déjà présent donne `updated`. Un fichier absent donne `installed`. Les textes sont `AGENTS.md installed`, `AGENTS.md updated`, `formats installed`, `formats updated`, `index-symbols.py installed`, `index-symbols.py updated`. `formats updated` dès qu'un fichier de `formats/` était déjà là. Les lignes manquantes `registry.sqlite`, `registry.sqlite-journal`, `registry.sqlite-wal` et `registry.sqlite-shm` sont ajoutées à `.gitignore`. Le reste de ce fichier reste. `.gitignore` n'est pas déplacé.

Le script se termine par `Ready:`, la destination, et `Repository: <login>/<name>`.

Si le dossier existe, ou si un chemin existant est donné, les fichiers sont indexés dans `registry.sqlite` et des `MODULE.md` manquants sont ajoutés.

La racine de ce dépôt, ouverte dans Herdr, répond `protocol repo` et n'écrit rien.

## Mise à jour

```bash
bash scripts/update.sh
```

`scripts/update.sh` prend pour racine le parent de `scripts/`. Sans `origin`, il quitte avec le code 1 et affiche `No origin.`. HEAD détaché : il quitte avec le code 1 et affiche `Detached head.`. Le pull est `git pull --ff-only origin` suivi de la branche courante. Aucun amont n'est requis. Un pull qui se termine avec le code 0 continue, même si un autre chemin du protocole est sale. Si le pull échoue et qu'un chemin du protocole reste, le script quitte avec le code 1, affiche `Dirty tree.`, puis liste ces chemins, un par ligne. Si le pull échoue et qu'aucun chemin du protocole ne reste, il affiche l'erreur de git et quitte avec le code 1. `.Trash-1000/` et `.idea/` ne rendent pas l'arbre sale. Les chemins sous `projects/` ne rendent pas la racine sale. Il ne clone rien et ne déplace aucun fichier étranger. Il ne lit aucune entrée. Il ne copie pas `README.md`. Il ne fait aucun commit et aucun push.

Après un pull réussi, chaque dossier de `projects/*` est rapporté par son nom de base. Le script affiche `<name>: updated` ou `<name>: current`.

Sous `updated`, un chemin relatif par ligne, indenté de deux espaces. Seuls les chemins qui différaient ou qui manquaient sont listés, dans cet ordre : `AGENTS.md`, les `formats/<file>` par nom de base, `scripts/index-symbols.py`, `.gitignore`, `registry.sqlite`. Un projet `current` ne liste rien.

`AGENTS.md`, chaque fichier de `formats/` et `scripts/index-symbols.py` sont copiés seulement lorsqu'ils manquent ou que les octets diffèrent. Des octets identiques ne sont pas recopiés. Les autres fichiers du projet restent.

Un `registry.sqlite` absent est créé depuis `formats/registry.sql` et listé. Une base déjà présente reçoit ce schéma, n'est pas listée, et ne suffit pas à rendre le projet `updated`.

`.gitignore` conserve ses autres lignes. Il est listé seulement si `registry.sqlite`, `registry.sqlite-journal`, `registry.sqlite-wal` ou `registry.sqlite-shm` manquait et a été ajouté. Le script ne remplace pas `.gitignore` par un autre fichier.

`scripts/check.sh` ferme, avant de supprimer son dossier temporaire, chaque workspace Herdr dont `checkout_path` ou `repo_root` est dans ce dossier. Il ne ferme aucun autre workspace. Le test smoke retire toujours le worktree lié avec `herdr worktree remove`, puis vérifie qu'aucun workspace du dossier temporaire ne reste.

Règles du projet : `projects/<name>/rules/AGENT-<n>-<NAME>.md`. Lues après `AGENTS.md`, par numéro. `AGENTS.md` ne se modifie pas. Dossier vide = pas de règle en plus.

## Après un prompt

1. Classe du message. `ask` : réponse dans l'onglet, sans fichier, sans agent. `git` : commit ou push déjà décidé, commentaire dans le message, orchestrateur seul. `publish:` vide : commit des owns, puis `git push` du dépôt du projet. `publish:` rempli : cette commande, avec le commentaire. `edit` : la phrase nomme un changement de fichiers. Le hash et les modules ne concernent qu'un `edit`. Avant un `git` ou un `edit`, un diff qui n'a que des modes est restauré depuis HEAD. S'il revient, `core.fileMode` passe à `false`. Aucun module ne s'ouvre pour ça.
2. Hash dans `registry.sqlite`. Un `edit` déjà vu, qui a déjà un enfant module, devient un pointeur et s'arrête. Un `ask` n'est pas enregistré.
3. Depth 1 = module. Depth 2 = un agent. `split: plan` ajoute un plan, commité avant l'impl. Découpage par domaine indépendant : graphisme, base de données, UX, core, ou un autre domaine sans chemin commun. Owns disjoints et `imports` vide : départ ensemble. `imports` : départ après la fusion des modules nommés. Le prompt reçoit au plus 50 noms de fichiers de chaque module importé, ceux que la tâche nomme, sinon les 50 premiers, puis le décompte `<n> more`. Le temps est celui du module le plus lent.
4. Une clé `impl-<techs>`. `plan-<techs>` seulement avec `split: plan`. Source 80 lignes, une fois. Une clé présente n'est pas réécrite.
5. Worktree Herdr d'abord, `--no-focus`, base `main`, branche `mod-<module>`. Un agent, un processus. Il écrit le plan puis le code. `split: plan` : le second worktree a pour base `mod-<module>-plan`. `git: nested` : le worktree et le commit sont dans ce dépôt. Ids lus dans le JSON : `result.workspace.workspace_id`, `result.tab.tab_id`, `result.root_pane.pane_id`, `result.worktree.path`.
6. Extraits via `symbols` du module, sinon `rg`. Trois fichiers, 40 lignes. Un fichier de `laws:` est collé en entier. Le fichier à modifier, sous 200 lignes, est collé en entier. Après la fusion, `python3 scripts/index-symbols.py <module>` : un `ast-grep` par motif, sur les fichiers changés, pas sur leur dossier. Les fichiers inchangés sont sautés. Un fichier de plus de 1 Mio n'est pas hashé. `sh` et `bash` : nœud `function_definition`. Un `.vue` est lu par son bloc `<script>`, en TypeScript par défaut.
7. Verrous dans `locks`, 600 s, la même durée que `--timeout 600000`. Chemin déjà pris : la tâche reste `open`, les autres modules partent. Prompts lancés ensemble, un processus chacun : `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000 &`. `wait -n` au prochain agent terminé. Un timeout ouvre un second prompt dans le même panneau, verrou renouvelé. Un second timeout, ou un agent mort : le module est `failed`, le verrou est retiré, le worktree est fermé. La demande ne reste pas `open`. Pas de troisième prompt.
8. Le bloc `status` / `files` / `config` est le dernier bloc. La prose au-dessus est ignorée. Un chemin hors owns, un fichier annoncé manquant, ou un `check` en échec : même pane, une fois. Purge si l'agent est mort ou si un chemin sort de owns.
9. Après le commit, `herdr worktree remove --workspace <id> --force` ferme le workspace, l'onglet et le panneau ouverts pour cet agent. La branche git reste. L'onglet de l'orchestrateur reste ouvert. Workspace déjà absent : `git worktree remove` sur le checkout. `git: parent` : fusion `git merge --no-ff mod-<module>` dans le projet. `git: nested` : pas de fusion de ces chemins dans le parent. `check:` vide : rien. `check:` rempli : la commande dans le worktree après le commit, avant la fusion.

Fin d'un edit qui a changé des fichiers : trois lignes, les fichiers, la commande de vérification, ce qui n'a pas été exécuté. L'orchestrateur dit si les README du produit sont à jour, ou que ce changement n'en a pas. Il demande s'il faut pousser, et le commentaire exact. Il ne pousse pas dans ce tour. Un worker n'écrit pas cette question.
