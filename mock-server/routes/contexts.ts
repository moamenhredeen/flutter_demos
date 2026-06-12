import { Router } from "express";
import * as Contexts from "../services/contexts.service";

const router = Router();

router.get('/', (_, res) => res.json(Contexts.getContexts()));

export default router;
