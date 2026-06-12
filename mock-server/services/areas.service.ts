import { db } from "../db";
import type { Area } from "../types";

export function getAreas(): Area[] {
  return db.prepare("SELECT * FROM areas ORDER BY name").all() as Area[];
}
