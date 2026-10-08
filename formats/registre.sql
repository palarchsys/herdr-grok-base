CREATE TABLE IF NOT EXISTS demandes (
  hash TEXT PRIMARY KEY,
  id TEXT NOT NULL,
  parent TEXT,
  depth INTEGER NOT NULL CHECK (depth IN (0, 1, 2)),
  module TEXT,
  config TEXT,
  statut TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS fichiers (
  path TEXT PRIMARY KEY,
  module TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS symboles (
  path TEXT NOT NULL,
  nom TEXT NOT NULL,
  kind TEXT NOT NULL,
  ligne INTEGER NOT NULL,
  PRIMARY KEY (path, nom, ligne)
);

CREATE TABLE IF NOT EXISTS verrous (
  path TEXT PRIMARY KEY,
  agent TEXT NOT NULL,
  demande TEXT NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS fichiers_module ON fichiers(module);
CREATE INDEX IF NOT EXISTS symboles_nom ON symboles(nom);
