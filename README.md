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

Le script saute une étape déjà faite. Il n'écrit pas dans `~/.grok`.

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

La base n'est pas créée ici. Elle l'est au lancement, depuis `formats/registry.sql`. Tables : `requests`, `files`, `symbols`, `locks`. `registry.sqlite` est ignoré par git.

## Nouveau projet

```bash
bash scripts/new-project.sh
source ~/.bashrc && herdr-<name>
```

Le script ne remplace aucun fichier déjà présent. Si le dossier existe, ou si un chemin existant est donné, le code est indexé dans `registry.sqlite` et des `MODULE.md` manquants sont ajoutés. Rien n'est déplacé.

`herdr-<name>` ouvre Herdr dans ce dossier.

Règles du projet : `projects/<name>/rules/AGENT-<n>-<NAME>.md`. Lues après `AGENTS.md`, par numéro. `AGENTS.md` ne se modifie pas. Dossier vide = pas de règle en plus.

## Après un prompt

1. Hash dans `registry.sqlite`. Déjà vu → pointeur, stop.
2. Depth 1 = module, depth 2 = plan puis impl.
3. `configs/plan-vue.md`, `configs/impl-vue.md`. Source 80 lignes, une fois.
4. Tabs `<module>-plan` et `<module>`. Worktree Herdr.
5. Extraits via `symbols`, sinon `rg`. Après `done`, `ast-grep` remplit `symbols`.
6. Verrous dans `locks`, 900 s. Tâches sans path commun en parallèle. Timeout 600000.
7. Deux fails ou path hors owns → fermer tab, `herdr worktree remove`, agent neuf.
