export type TaskStatus = 'inbox' | 'next_action' | 'waiting_for' | 'someday' | 'reference' | 'done';
export type Energy = 'low' | 'medium' | 'high';

export interface Task {
  id: number;
  title: string;
  notes: string | null;
  status: TaskStatus;
  energy: Energy | null;
  time_estimate: number | null;
  due_date: string | null;
  created_at: string;
  project: { id: number; title: string } | null;
  context: { id: number; name: string; icon: string } | null;
  area: { id: number; name: string } | null;
}

export interface Project {
  id: number;
  title: string;
  status: 'active' | 'completed' | 'someday';
  area: { id: number; name: string } | null;
  task_count: number;
}

export interface Context {
  id: number;
  name: string;
  icon: string;
}

export interface Area {
  id: number;
  name: string;
}

export interface OffsetPage<T> {
  items: T[];
  total: number;
  page: number;
  per_page: number;
  pages: number;
}

export interface CursorPage<T> {
  items: T[];
  next_cursor: string | null;
  has_more: boolean;
}
