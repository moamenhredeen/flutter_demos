import { Router } from "express";
import * as Areas from "../services/areas.service";

const router = Router();

router.get('/', (_, res) => res.json(Areas.getAreas()));

export default router;
