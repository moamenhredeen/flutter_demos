
export function parsePage(page: any): number {
	return Math.max(1, Number(page) || 1);
}

export function parseLimit(limit: any): number {
	return Math.min(100, Math.max(1, Number(limit) || 20));
}
