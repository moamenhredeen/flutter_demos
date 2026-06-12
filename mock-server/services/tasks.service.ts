import { db } from "../db";
import type { Task, OffsetPage, CursorPage } from "../types";

const BASE_SELECT = `
  SELECT
    t.id, t.title, t.notes, t.status, t.energy,
    t.time_estimate, t.due_date, t.created_at,
    t.project_id, p.title  AS project_title,
    t.context_id, c.name   AS context_name, c.icon AS context_icon,
    t.area_id,    a.name   AS area_name
  FROM tasks t
  LEFT JOIN projects p ON t.project_id = p.id
  LEFT JOIN contexts c ON t.context_id = c.id
  LEFT JOIN areas    a ON t.area_id    = a.id
`;

function shape(row: Record<string, any>): Task {
  return {
    id: row.id,
    title: row.title,
    notes: row.notes,
    status: row.status,
    energy: row.energy,
    time_estimate: row.time_estimate,
    due_date: row.due_date,
    created_at: row.created_at,
    project: row.project_id ? { id: row.project_id, title: row.project_title } : null,
    context: row.context_id ? { id: row.context_id, name: row.context_name, icon: row.context_icon } : null,
    area:    row.area_id    ? { id: row.area_id,    name: row.area_name }                            : null,
  };
}

const FILTER_KEYS = ['status', 'energy', 'project_id', 'context_id', 'area_id'] as const;

function buildWhere(
  filters: Record<string, any>,
  extra: { clauses?: string[]; params?: any[] } = {},
) {
  const clauses: string[] = [];
  const params:  any[]    = [];

  for (const key of FILTER_KEYS) {
    if (filters[key] != null) {
      clauses.push(`t.${key} = ?`);
      params.push(filters[key]);
    }
  }

  if (extra.clauses?.length) {
    clauses.push(...extra.clauses);
    params.push(...(extra.params ?? []));
  }

  return { where: clauses.length ? `WHERE ${clauses.join(' AND ')}` : '', params };
}

export function getTasks(
  filters: Record<string, any>,
  page: number,
  perPage: number,
): OffsetPage<Task> {
  const offset = (page - 1) * perPage;
  const { where, params } = buildWhere(filters);

  const { count } = db.prepare(`SELECT COUNT(*) as count FROM tasks t ${where}`)
    .get(...params) as { count: number };

  const rows = db.prepare(`${BASE_SELECT} ${where} ORDER BY t.created_at DESC LIMIT ? OFFSET ?`)
    .all(...params, perPage, offset) as any[];

  return { items: rows.map(shape), total: count, page, per_page: perPage, pages: Math.ceil(count / perPage) };
}

export function getTasksCursor(
  filters: Record<string, any>,
  cursor: string | undefined,
  limit: number,
): CursorPage<Task> {
  const extra = cursor
    ? { clauses: ['t.id < ?'], params: [Number(atob(cursor))] }
    : {};

  const { where, params } = buildWhere(filters, extra);

  const rows = db.prepare(`${BASE_SELECT} ${where} ORDER BY t.id DESC LIMIT ?`)
    .all(...params, limit + 1) as any[];

  const hasMore = rows.length > limit;
  const items   = rows.slice(0, limit).map(shape);

  return {
    items,
    next_cursor: hasMore ? btoa(String(items[items.length - 1].id)) : null,
    has_more: hasMore,
  };
}

export function getTaskById(id: string | number): Task | null {
  const row = db.prepare(`${BASE_SELECT} WHERE t.id = ?`).get(id) as any;
  return row ? shape(row) : null;
}

export function createTask(data: Record<string, any>): Task {
  const { title, notes, status = 'inbox', energy, time_estimate, due_date, project_id, context_id, area_id } = data;

  const { id } = db.prepare(`
    INSERT INTO tasks (title, notes, status, energy, time_estimate, due_date, created_at, project_id, context_id, area_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING id
  `).get(
    title, notes ?? null, status, energy ?? null, time_estimate ?? null,
    due_date ?? null, new Date().toISOString(), project_id ?? null, context_id ?? null, area_id ?? null,
  ) as { id: number };

  return getTaskById(id)!;
}

const UPDATABLE_FIELDS = ['title', 'notes', 'status', 'energy', 'time_estimate', 'due_date', 'project_id', 'context_id', 'area_id'];

export function updateTask(id: string | number, data: Record<string, any>): Task | null {
  if (!db.prepare("SELECT id FROM tasks WHERE id = ?").get(id)) return null;

  const fields = UPDATABLE_FIELDS.filter(f => data[f] !== undefined);
  if (fields.length) {
    db.prepare(`UPDATE tasks SET ${fields.map(f => `${f} = ?`).join(', ')} WHERE id = ?`)
      .run(...fields.map(f => data[f]), id);
  }

  return getTaskById(id)!;
}

export function deleteTask(id: string | number): boolean {
  if (!db.prepare("SELECT id FROM tasks WHERE id = ?").get(id)) return false;
  db.prepare("DELETE FROM tasks WHERE id = ?").run(id);
  return true;
}
