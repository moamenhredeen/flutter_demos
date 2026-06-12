import { Database } from "bun:sqlite";
import { join } from "path";

export const db = new Database(join(import.meta.dir, "data.db"), { create: true });

db.run(`
  CREATE TABLE IF NOT EXISTS areas (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS contexts (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    icon TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS projects (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    title   TEXT NOT NULL,
    area_id INTEGER REFERENCES areas(id),
    status  TEXT NOT NULL DEFAULT 'active'
  );

  CREATE TABLE IF NOT EXISTS tasks (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    title         TEXT NOT NULL,
    notes         TEXT,
    status        TEXT NOT NULL DEFAULT 'inbox',
    energy        TEXT,
    time_estimate INTEGER,
    due_date      TEXT,
    created_at    TEXT NOT NULL,
    project_id    INTEGER REFERENCES projects(id),
    context_id    INTEGER REFERENCES contexts(id),
    area_id       INTEGER REFERENCES areas(id)
  );

  CREATE INDEX IF NOT EXISTS idx_tasks_status     ON tasks(status);
  CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);
  CREATE INDEX IF NOT EXISTS idx_tasks_project    ON tasks(project_id);
  CREATE INDEX IF NOT EXISTS idx_tasks_context    ON tasks(context_id);
  CREATE INDEX IF NOT EXISTS idx_tasks_area       ON tasks(area_id);
`);
