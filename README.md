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

`scripts/update.sh` prend pour racine le parent de `scripts/`. Sans `origin`, il quitte avec le code 1 et affiche `No origin.`. Il lance `git pull --ff-only`. Un arbre sale n'arrête pas le script lorsque `git pull --ff-only` réussit. Si le pull échoue parce que l'arbre du protocole est sale, le script quitte avec le code 1, affiche `Dirty tree.`, puis liste ces chemins, un par ligne. Si le pull échoue et que l'arbre du protocole est propre, il affiche l'erreur de git et quitte avec le code 1. Les chemins sous `projects/` ne rendent pas la racine sale. Il ne clone rien et ne déplace aucun fichier étranger.

Chaque dossier de `projects/*` reçoit la même écriture : `AGENTS.md`, les fichiers de `formats/`, `scripts/index-symbols.py`, le schéma `formats/registry.sql`, et les lignes manquantes de `.gitignore`.

Le script pose ensuite deux questions. Il répète chacune jusqu'à `Oui`, `oui`, `O`, `o`, `Non`, `non`, `N` ou `n`.

`Mise a jour des readmes ? Oui/Non :` — Oui copie le `README.md` de la racine sur chaque `projects/<name>/README.md`. Non passe à la question suivante.

`Commit et push vers le depot ? Oui/Non :` — Oui demande `Commentaire : `. Un commentaire vide quitte avec le code 1. Pour la racine et chaque `projects/*` qui contient `.git`, un arbre sale reçoit un commit avec ce message, puis `git push`. La racine fait `git add -A` sans `projects/`. Chaque projet fait `git add -A`. Un dépôt propre est ignoré. Un push qui échoue quitte avec le code 1. Non quitte avec le code 0.

`scripts/check.sh` ferme, avant de supprimer son dossier temporaire, chaque workspace Herdr dont `checkout_path` ou `repo_root` est dans ce dossier. Il ne ferme aucun autre workspace. Le test smoke retire toujours le worktree lié avec `herdr worktree remove`, puis vérifie qu'aucun workspace du dossier temporaire ne reste.

Règles du projet : `projects/<name>/rules/AGENT-<n>-<NAME>.md`. Lues après `AGENTS.md`, par numéro. `AGENTS.md` ne se modifie pas. Dossier vide = pas de règle en plus.

## Après un prompt

1. Hash dans `registry.sqlite`. Déjà vu → pointeur, stop.
2. Depth 1 = module, depth 2 = plan puis impl. Découpage par domaine indépendant : graphisme, base de données, UX, core, ou un autre domaine sans chemin commun. Plusieurs modules d'un domaine partent ensemble. Un module = un agent plan, puis un agent impl. Le temps est celui du module le plus lent.
3. `configs/plan-vue.md`, `configs/impl-vue.md`. Source 80 lignes, une fois.
4. Worktree Herdr d'abord, `--no-focus`. Plan : `--base main`. Impl : `--base mod-<module>-plan`, après le commit du plan. Ids lus dans le JSON : `result.workspace.workspace_id`, `result.tab.tab_id`, `result.root_pane.pane_id`, `result.worktree.path`.
5. Extraits via `symbols` du module, sinon `rg`. Après `done`, `python3 scripts/index-symbols.py <module>` : un `ast-grep` par motif, les fichiers inchangés sont sautés. Un `.vue` est lu par son bloc `<script>`, en TypeScript par défaut.
6. Verrous dans `locks`, 900 s. Chemin déjà pris : la tâche reste `open`, les autres modules partent. Prompts de plan lancés ensemble, un processus chacun : `herdr agent prompt <name> <text> --wait --until idle --until done --timeout 600000 &`. `wait -n` au prochain agent terminé. Ce plan est fermé, puis son impl part tout de suite, sans attendre les autres plans.
7. Après le commit du plan ou de l'impl, `herdr worktree remove --workspace <id> --force` ferme le workspace, l'onglet et le panneau ouverts pour cet agent. La branche git reste. L'onglet de l'orchestrateur reste ouvert. Workspace déjà absent : `git worktree remove` sur le checkout. Deux fails ou path hors owns → la même fermeture, puis un agent neuf. Fusion : `git merge --no-ff mod-<module>` dans le projet, après la fermeture du checkout d'impl. Cette branche reste et contient les commits du plan.
