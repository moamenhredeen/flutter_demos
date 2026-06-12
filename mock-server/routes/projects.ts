import { Router } from "express";
import * as Projects from "../services/projects.service";
import { parseLimit, parsePage } from "./utils";

const router = Router();

router.get('/', (_, res) => {
	res.json(Projects.getProjects());
});

router.get('/:id/tasks', (req, res) => {
	const page = parsePage(req.query.page);
	const perPage = parseLimit(req.query.per_page);
	res.json(Projects.getProjectTasks(req.params.id, req.query as any, page, perPage));
});

export default router;
