CREATE TABLE IF NOT EXISTS requests (
  hash TEXT PRIMARY KEY,
  id TEXT NOT NULL,
  parent TEXT,
  depth INTEGER NOT NULL CHECK (depth IN (0, 1, 2)),
  module TEXT,
  config TEXT,
  status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS files (
  path TEXT PRIMARY KEY,
  module TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS symbols (
  path TEXT NOT NULL,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  line INTEGER NOT NULL,
  PRIMARY KEY (path, name, line)
);

CREATE TABLE IF NOT EXISTS locks (
  path TEXT PRIMARY KEY,
  agent TEXT NOT NULL,
  request TEXT NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS files_module ON files(module);
CREATE INDEX IF NOT EXISTS symbols_name ON symbols(name);
CREATE INDEX IF NOT EXISTS requests_parent ON requests(parent);
CREATE INDEX IF NOT EXISTS requests_module_status ON requests(module, status);
