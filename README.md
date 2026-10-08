# Forge orchestrateur

Grok ne lit pas ce README. Il lit `AGENTS.md`. `grok inspect` doit le lister.

## Installation

```bash
curl -fsSL https://herdr.dev/install.sh | sh
curl -fsSL https://x.ai/cli/install.sh | bash
grok login
herdr integration install grok
# sqlite3, rg, ast-grep dans le PATH
mkdir -p demandes configs/sources agents/clos modules formats
cp AGENTS.md <repo>/AGENTS.md
cp -R formats <repo>/formats
cd <repo> && sqlite3 registre.sqlite < formats/registre.sql
herdr
test "${HERDR_ENV:-}" = 1
grok inspect && grok
```

## Après un prompt

1. Hash dans `demandes` de `registre.sqlite`. Déjà vu → pointeur, stop.
2. Depth 1 = module, depth 2 = plan puis impl.
3. `configs/plan-vue.md`, `configs/impl-vue.md`. Source 80 lignes, une fois.
4. Tabs `<module>-plan` et `<module>`. Worktree Herdr.
5. Extraits via table `symboles`, sinon `rg`. Après `done`, `ast-grep` remplit `symboles`.
6. Verrous dans SQLite, 900 s. Tâches sans path commun en parallèle. Timeout 600000.
7. Deux fails ou path hors owns → fermer tab, `herdr worktree remove`, agent neuf.

## Chemins

| Chemin | Rôle |
| --- | --- |
| `AGENTS.md` | procédure |
| `formats/` | formulaires |
| `formats/registre.sql` | schéma, lancé une fois |
| `registre.sqlite` | demandes, fichiers, symboles, verrous |
| `demandes/<id>.md` | corps de la demande |
| `configs/<cle>.md` | modèle d'agent |
| `configs/sources/<cle>.md` | extraits techno |
| `modules/<id>/MODULE.md` | owns |
| `modules/<id>/PLAN.md` | écrit du tab plan |
| `agents/<nom>.md` | tab, pane, worktree |
| `agents/clos/` | purgés |
