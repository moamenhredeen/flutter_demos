import { Router } from "express";
import * as Tasks from "../services/tasks.service";
import { parseLimit, parsePage } from "./utils";

const router = Router();

const UPDATABLE = ['title', 'notes', 'status', 'energy', 'time_estimate', 'due_date', 'project_id', 'context_id', 'area_id'];

router.get('/', (req, res) => {
	const page = parsePage(req.query.page);
	const perPage = parseLimit(req.query.per_page);
	res.json(Tasks.getTasks(req.query as any, page, perPage));
});

router.get('/cursor', (req, res) => {
	const limit = parseLimit(req.query.limit);
	res.json(Tasks.getTasksCursor(req.query as any, req.query.cursor as string | undefined, limit));
});

router.get('/:id', (req, res) => {
	const task = Tasks.getTaskById(req.params.id);
	if (!task) return res.status(404).json({ error: 'Task not found' });
	res.json(task);
});

router.post('/', (req, res) => {
	if (!req.body.title) return res.status(400).json({ error: 'title is required' });
	res.status(201).json(Tasks.createTask(req.body));
});

router.patch('/:id', (req, res) => {
	if (!UPDATABLE.some(f => req.body[f] !== undefined))
		return res.status(400).json({ error: 'No valid fields to update' });

	const task = Tasks.updateTask(req.params.id, req.body);
	if (!task) return res.status(404).json({ error: 'Task not found' });
	res.json(task);
});

router.delete('/:id', (req, res) => {
	if (!Tasks.deleteTask(req.params.id))
		return res.status(404).json({ error: 'Task not found' });
	res.json({ success: true });
});

export default router;
