# Forge orchestrateur

Grok ne lit pas ce README. Il lit `AGENTS.md` du projet lancé. `grok inspect` doit le lister.

La racine de ce dépôt est le protocole. Grok n'y écrit pas.

```
herdr-grok-base/
  AGENTS.md
  README.md
  formats/
  regles/
  projets/
    <nom>/
      AGENTS.md
      formats/
      regles/
        AGENT-0-SQL.md
        AGENT-1-MD.md
      demandes/
      configs/sources/
      agents/clos/
      modules/
      src/
      registre.sqlite
```

## Installation de base

Ubuntu 26.04 uniquement.

```bash
curl -fsSL https://herdr.dev/install.sh | sh
curl -fsSL https://x.ai/cli/install.sh | bash
grok login
herdr integration install grok
```

```bash
git clone git@github.com:palarchsys/herdr-grok-base.git
cd herdr-grok-base
mkdir -p projets
```

## Outils Ubuntu 26.04

`sqlite3`, `rg`, `ast-grep`.

```bash
sudo apt-get update
sudo apt-get install -y sqlite3 ripgrep curl unzip
```

`ast-grep` n'est pas dans apt. Le binaire Linux s'appelle `sg`. Le protocole appelle `ast-grep`.

```bash
cd /tmp
wget -qO ast-grep.zip https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-gnu.zip
sudo unzip -q -o ast-grep.zip -d /usr/local/bin
sudo ln -sfn /usr/local/bin/sg /usr/local/bin/ast-grep
rm -f ast-grep.zip
```

Vérifier :

```bash
sqlite3 --version
rg --version
ast-grep --version
```

Les trois commandes doivent répondre. Sinon ne pas lancer de projet.

La base n'est pas créée ici. Elle l'est au lancement, depuis `formats/registre.sql`. Tables : `demandes`, `fichiers`, `symboles`, `verrous`. `registre.sqlite` est ignoré par git.

## Lancement d'un projet

Un dossier par projet. Grok démarre dedans, pas à la racine.

```bash
cd herdr-grok-base
nom=<nom>
mkdir -p projets/$nom/{demandes,configs/sources,agents/clos,modules,src,formats,regles}
cp AGENTS.md projets/$nom/AGENTS.md
cp -R formats/. projets/$nom/formats/
sqlite3 projets/$nom/registre.sqlite < formats/registre.sql
sqlite3 projets/$nom/registre.sqlite ".tables"
cd projets/$nom
git init
herdr
test "${HERDR_ENV:-}" = 1
grok inspect && grok
```

`grok inspect` doit lister `projets/<nom>/AGENTS.md`. Sinon ne pas prompt.

Ensuite un prompt dans ce tab. L'orchestrateur écrit sous `projets/<nom>/` seulement.

Règles du projet : `projets/<nom>/regles/AGENT-<n>-<NOM>.md`. Lues après `AGENTS.md`, par numéro. `AGENTS.md` ne se modifie pas. Exemple : `AGENT-0-SQL.md`, `AGENT-1-MD.md`. Dossier vide = pas de règle en plus.

## Après un prompt

1. Hash dans `registre.sqlite`. Déjà vu → pointeur, stop.
2. Depth 1 = module, depth 2 = plan puis impl.
3. `configs/plan-vue.md`, `configs/impl-vue.md`. Source 80 lignes, une fois.
4. Tabs `<module>-plan` et `<module>`. Worktree Herdr.
5. Extraits via `symboles`, sinon `rg`. Après `done`, `ast-grep` remplit `symboles`.
6. Verrous SQLite, 900 s. Tâches sans path commun en parallèle. Timeout 600000.
7. Deux fails ou path hors owns → fermer tab, `herdr worktree remove`, agent neuf.
