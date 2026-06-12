import express from "express";
import tasksRouter from "./routes/tasks";
import projectsRouter from "./routes/projects";
import contextsRouter from "./routes/contexts";
import areasRouter from "./routes/areas";

const app = express();

app.use(express.json());

// Network simulation — append to any request:
//   ?delay=2000          → artificial latency (max 10s)
//   ?simulate_error=true → force 500
app.use(async (req, res, next) => {
	if (req.query.simulate_error === 'true')
		return res.status(500).json({ error: 'Simulated server error' });

	const delay = Number(req.query.delay);
	if (delay > 0) await new Promise(r => setTimeout(r, Math.min(delay, 10_000)));

	next();
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

app.use('/tasks', tasksRouter);
app.use('/projects', projectsRouter);
app.use('/contexts', contextsRouter);
app.use('/areas', areasRouter);

const baseUrl = 'http://localhost:5000'
app.listen(5000, () => {
	console.log(`
  Mock server: ${baseUrl}
  
  Endpoints:
    GET     ${baseUrl}/tasks?page=1&per_page=20[&status&context_id&area_id&energy&project_id]
    GET     ${baseUrl}/tasks/cursor?limit=20[&cursor&status&context_id&area_id&energy]
    GET     ${baseUrl}/tasks/:id
    POST    ${baseUrl}/tasks
    PATCH   ${baseUrl}/tasks/:id
    DELETE  ${baseUrl}/tasks/:id
    GET     ${baseUrl}/projects
    GET     ${baseUrl}/projects/:id/tasks?page=1&per_page=20
    GET     ${baseUrl}/contexts
    GET     ${baseUrl}/areas
    
   Simulation: append ?delay=1000 or ?simulate_error=true to any request`);
});

