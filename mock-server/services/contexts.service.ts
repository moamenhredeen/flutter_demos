import { db } from "../db";
import type { Context } from "../types";

export function getContexts(): Context[] {
  return db.prepare("SELECT * FROM contexts ORDER BY name").all() as Context[];
}
