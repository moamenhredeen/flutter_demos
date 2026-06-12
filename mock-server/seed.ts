import { SQLQueryBindings } from "bun:sqlite";
import { db } from "./db";

// Clear in FK order
db.run("DELETE FROM tasks");
db.run("DELETE FROM projects");
db.run("DELETE FROM contexts");
db.run("DELETE FROM areas");

const seqExists = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='sqlite_sequence'").get();
if (seqExists) db.run("DELETE FROM sqlite_sequence");

// ── Static data ──────────────────────────────────────────────────────────────

db.run(`
  INSERT INTO areas (id, name) VALUES
    (1, 'Work'), (2, 'Health'), (3, 'Finance'), (4, 'Personal'), (5, 'Learning')
`);

db.run(`
  INSERT INTO contexts (id, name, icon) VALUES
    (1, '@computer', '💻'),
    (2, '@home',     '🏠'),
    (3, '@errands',  '🚗'),
    (4, '@calls',    '📞'),
    (5, '@online',   '🌐'),
    (6, '@anywhere', '📍')
`);

db.run(`
  INSERT INTO projects (id, title, area_id, status) VALUES
    (1,  'Q3 Product Launch',           1, 'active'),
    (2,  'Hire Senior Developer',        1, 'active'),
    (3,  'Refactor Auth Module',         1, 'active'),
    (4,  'Morning Routine System',       2, 'active'),
    (5,  'Marathon Training',            2, 'active'),
    (6,  'Tax Filing 2024',             3, 'active'),
    (7,  'Investment Portfolio Review',  3, 'active'),
    (8,  'Home Renovation',             4, 'active'),
    (9,  'Trip to Japan',               4, 'someday'),
    (10, 'Flutter Mastery',             5, 'active'),
    (11, 'Read 12 Books This Year',     5, 'active'),
    (12, 'Learn German',                5, 'someday')
`);

// ── Task title pool ───────────────────────────────────────────────────────────

const titles = [
	// Work
	"Review pull request for authentication module",
	"Write unit tests for payment service",
	"Update API documentation",
	"Fix login redirect bug",
	"Schedule sprint planning meeting",
	"Prepare Q3 roadmap presentation",
	"Do code review for team member",
	"Set up CI/CD pipeline",
	"Refactor database queries for performance",
	"Deploy hotfix to production",
	"Interview candidate for senior engineer role",
	"Write onboarding documentation for new hire",
	"Analyse user drop-off in onboarding funnel",
	"Bump dependencies to latest versions",
	"Design Figma mockups for new feature",
	// Health
	"Book annual physical checkup",
	"Research protein supplement options",
	"Schedule dentist appointment",
	"Buy new running shoes",
	"Log workout in fitness app",
	"Research sleep tracking devices",
	"Order vitamins online",
	"Schedule eye exam",
	"Try new yoga studio downtown",
	"Cook batch of healthy meals for the week",
	// Finance
	"Gather receipts for tax deductions",
	"Review monthly budget spreadsheet",
	"Transfer to emergency savings account",
	"Check investment portfolio performance",
	"Research index fund options",
	"Cancel unused software subscriptions",
	"Update emergency fund target",
	"Review insurance coverage gaps",
	"File expense report for conference",
	"Research mortgage refinancing options",
	// Personal
	"Call parents this weekend",
	"Plan birthday dinner for partner",
	"Research Japan visa requirements",
	"Book return flight tickets",
	"Clean out and organise garage",
	"Fix leaking kitchen faucet",
	"Research interior paint colours for living room",
	"Organise digital photo library",
	"Write in daily journal",
	"Catch up with old college friend",
	// Learning
	"Read chapter 5 of Clean Code",
	"Watch Flutter state management tutorial",
	"Practice German on Duolingo for 20 minutes",
	"Complete TypeScript generics module",
	"Write blog post about Riverpod patterns",
	"Summarise key notes from last book",
	"Join online Flutter study group",
	"Solve 3 LeetCode problems",
	"Watch conference talk on clean architecture",
	"Review spaced repetition flashcards",
];

// Weighted status distribution — more inbox/next_action than the rest
const statusPool = [
	'inbox', 'inbox', 'inbox',
	'next_action', 'next_action', 'next_action', 'next_action',
	'waiting_for', 'waiting_for',
	'someday',
	'reference',
	'done', 'done',
];
const energyPool = ['low', 'medium', 'high', null, null];
const timePool = [5, 10, 15, 20, 30, 45, 60, 90, 120, null, null];

// project_id → area_id
const projectArea: Record<number, number> = {
	1: 1, 2: 1, 3: 1,
	4: 2, 5: 2,
	6: 3, 7: 3,
	8: 4, 9: 4,
	10: 5, 11: 5, 12: 5,
};

const insert = db.prepare(`
  INSERT INTO tasks (title, notes, status, energy, time_estimate, due_date, created_at, project_id, context_id, area_id)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`);

const now = Date.now();
const sixMonthsAgo = now - 180 * 24 * 60 * 60 * 1000;

for (let i = 0; i < 500; i++) {
	const title = titles[i % titles.length];
	const status = statusPool[i % statusPool.length];
	const energy = energyPool[i % energyPool.length];
	const timeEst = timePool[i % timePool.length];
	const notes = i % 3 === 0 ? `Notes: ${title.toLowerCase()}` : null;
	const dueDate = i % 3 === 0
		? new Date(now + ((i % 60) - 30) * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
		: null;
	const createdAt = new Date(sixMonthsAgo + (i / 500) * (now - sixMonthsAgo)).toISOString();
	const projectId = i % 5 !== 0 ? (i % 12) + 1 : null;
	const areaId = projectId ? projectArea[projectId] : (i % 5) + 1;
	const contextId = i % 10 !== 0 ? (i % 6) + 1 : null;

	insert.run(title, notes, status, energy, timeEst, dueDate, createdAt, projectId, contextId, areaId);
}

console.log("Seeded: 5 areas, 6 contexts, 12 projects, 500 tasks");
