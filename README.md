# Forge orchestrateur

Grok ne lit pas ce README. Il lit `AGENTS.md` du projet lancé. `grok inspect` doit le lister.

La racine de ce dépôt est le protocole. Grok n'y écrit pas.

```
herdr-grok-base/
  AGENTS.md
  README.md
  formats/
  projets/
    <nom>/
      AGENTS.md
      formats/
      demandes/
      configs/sources/
      agents/clos/
      modules/
      src/
      registre.sqlite
```

## Installation de base

Une fois sur la machine.

```bash
curl -fsSL https://herdr.dev/install.sh | sh
curl -fsSL https://x.ai/cli/install.sh | bash
grok login
herdr integration install grok
```

`sqlite3`, `rg` et `ast-grep` doivent être dans le PATH.

```bash
git clone git@github.com:palarchsys/herdr-grok-base.git
cd herdr-grok-base
mkdir -p projets
```

## Lancement d'un projet

Un dossier par projet. Grok démarre dedans, pas à la racine.

```bash
cd herdr-grok-base
nom=<nom>
mkdir -p projets/$nom/{demandes,configs/sources,agents/clos,modules,src,formats}
cp AGENTS.md projets/$nom/AGENTS.md
cp -R formats/. projets/$nom/formats/
sqlite3 projets/$nom/registre.sqlite < formats/registre.sql
cd projets/$nom
git init
herdr
test "${HERDR_ENV:-}" = 1
grok inspect && grok
```

`grok inspect` doit lister `projets/<nom>/AGENTS.md`. Sinon ne pas prompt.

Ensuite un prompt dans ce tab. L'orchestrateur écrit sous `projets/<nom>/` seulement.

## Après un prompt

1. Hash dans `registre.sqlite`. Déjà vu → pointeur, stop.
2. Depth 1 = module, depth 2 = plan puis impl.
3. `configs/plan-vue.md`, `configs/impl-vue.md`. Source 80 lignes, une fois.
4. Tabs `<module>-plan` et `<module>`. Worktree Herdr.
5. Extraits via `symboles`, sinon `rg`. Après `done`, `ast-grep` remplit `symboles`.
6. Verrous SQLite, 900 s. Tâches sans path commun en parallèle. Timeout 600000.
7. Deux fails ou path hors owns → fermer tab, `herdr worktree remove`, agent neuf.
