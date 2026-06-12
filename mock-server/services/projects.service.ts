import { db } from "../db";
import type { Project, OffsetPage } from "../types";

export function getProjects(): Project[] {
	const rows = db.prepare(`
    SELECT p.id, p.title, p.status, p.area_id, a.name AS area_name,
           COUNT(t.id) AS task_count
    FROM projects p
    LEFT JOIN areas  a ON p.area_id    = a.id
    LEFT JOIN tasks  t ON t.project_id = p.id
    GROUP BY p.id
    ORDER BY p.area_id, p.title
  `).all() as any[];

	return rows.map(r => ({
		id: r.id,
		title: r.title,
		status: r.status,
		area: r.area_id ? { id: r.area_id, name: r.area_name } : null,
		task_count: r.task_count,
	}));
}

export function getProjectTasks(
	projectId: string | number,
	filters: { status?: string },
	page: number,
	perPage: number,
): OffsetPage<any> {
	const offset = (page - 1) * perPage;
	const clauses = ['t.project_id = ?'];
	const params: any[] = [projectId];

	if (filters.status) { clauses.push('t.status = ?'); params.push(filters.status); }

	const where = `WHERE ${clauses.join(' AND ')}`;

	const { count } = db
		.prepare(`SELECT COUNT(*) as count FROM tasks t ${where}`)
		.get(...params) as { count: number };

	const rows = db.prepare(`
    SELECT t.id, t.title, t.notes, t.status, t.energy, t.time_estimate, t.due_date, t.created_at,
           t.context_id, c.name AS context_name, c.icon AS context_icon,
           t.area_id,    a.name AS area_name
    FROM tasks t
    LEFT JOIN contexts c ON t.context_id = c.id
    LEFT JOIN areas    a ON t.area_id    = a.id
    ${where}
    ORDER BY t.created_at DESC
    LIMIT ? OFFSET ?
  `).all(...params, perPage, offset) as any[];

	return {
		items: rows.map(r => ({
			id: r.id,
			title: r.title,
			notes: r.notes,
			status: r.status,
			energy: r.energy,
			time_estimate: r.time_estimate,
			due_date: r.due_date,
			created_at: r.created_at,
			context: r.context_id ? {
				id: r.context_id,
				name: r.context_name,
				icon: r.context_icon
			} : null,
			area: r.area_id ? {
				id: r.area_id,
				name: r.area_name
			} : null,
		})),
		total: count,
		page,
		per_page: perPage,
		pages: Math.ceil(count / perPage),
	};
}
