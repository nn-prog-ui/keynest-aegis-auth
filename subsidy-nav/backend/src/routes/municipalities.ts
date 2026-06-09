import { Router, Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

// GET /api/municipalities/prefectures - 都道府県一覧
router.get('/prefectures', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const prefectures = await prisma.prefecture.findMany({
      orderBy: { code: 'asc' },
      include: {
        _count: { select: { municipalities: true, subsidies: true } },
      },
    });
    res.json(prefectures);
  } catch (err) {
    next(err);
  }
});

// GET /api/municipalities/prefectures/:code - 都道府県詳細 + 市区町村一覧
router.get(
  '/prefectures/:code',
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const prefecture = await prisma.prefecture.findUnique({
        where: { code: req.params.code },
        include: {
          municipalities: { orderBy: { code: 'asc' } },
          _count: { select: { subsidies: true } },
        },
      });
      if (!prefecture) throw new AppError(404, '都道府県が見つかりません');
      res.json(prefecture);
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/municipalities/:code - 市区町村詳細
router.get('/:code', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const municipality = await prisma.municipality.findUnique({
      where: { code: req.params.code },
      include: {
        prefecture: true,
        _count: { select: { subsidies: true } },
      },
    });
    if (!municipality) throw new AppError(404, '市区町村が見つかりません');
    res.json(municipality);
  } catch (err) {
    next(err);
  }
});

export default router;
