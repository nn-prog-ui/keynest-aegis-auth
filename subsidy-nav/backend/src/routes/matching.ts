import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { TargetAudience } from '@prisma/client';
import { matchSubsidies } from '../services/matchingService';
import { AppError } from '../middleware/errorHandler';

const router = Router();

const MatchProfileSchema = z.object({
  prefectureCode: z.string().optional(),
  municipalityCode: z.string().optional(),
  targetAudience: z.nativeEnum(TargetAudience),
  categoryIds: z.array(z.number()).optional(),
  budgetMin: z.number().optional(),
  isStartup: z.boolean().optional(),
  keywords: z.string().optional(),
});

// POST /api/matching - 補助金マッチング診断
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const profile = MatchProfileSchema.parse(req.body);
    const matches = await matchSubsidies(profile);
    res.json({ matches, count: matches.length });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return next(new AppError(400, err.errors[0].message));
    }
    next(err);
  }
});

export default router;
