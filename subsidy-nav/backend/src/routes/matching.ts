import { Router, Request, Response } from 'express';
import { matchSubsidies } from '../services/matchingService';

const router = Router();

router.post('/', async (req: Request, res: Response) => {
  try {
    const result = await matchSubsidies(req.body);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
