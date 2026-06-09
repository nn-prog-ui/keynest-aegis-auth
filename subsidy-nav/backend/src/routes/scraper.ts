import { Router, Request, Response } from 'express';
import { scrapeAll, scrapeMunicipality } from '../services/scraperService';
import { getTargetByCode } from '../data/scrape-targets';

const router = Router();

router.post('/run', async (_req: Request, res: Response) => {
  try {
    const result = await scrapeAll();
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Scrape failed' });
  }
});

router.post('/run/:code', async (req: Request, res: Response) => {
  try {
    const target = getTargetByCode(req.params.code);
    if (!target) return res.status(404).json({ error: 'Target not found' });
    const result = await scrapeMunicipality(target);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Scrape failed' });
  }
});

export default router;
