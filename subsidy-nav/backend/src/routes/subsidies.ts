import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PrismaClient, SubsidyStatus, TargetAudience } from '@prisma/client';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

const SearchSchema = z.object({
  keyword: z.string().optional(),
  prefectureCode: z.string().optional(),
  municipalityCode: z.string().optional(),
  categoryId: z.string().optional(),
  status: z.nativeEnum(SubsidyStatus).optional(),
  targetAudience: z.nativeEnum(TargetAudience).optional(),
  isNational: z.enum(['true', 'false']).optional(),
  deadlineBefore: z.string().optional(), // ISO date
  page: z.string().default('1'),
  limit: z.string().default('20'),
  sortBy: z.enum(['newest', 'deadline', 'amount']).default('newest'),
});

// GET /api/subsidies - 補助金一覧・検索
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const params = SearchSchema.parse(req.query);
    const page = parseInt(params.page);
    const limit = Math.min(parseInt(params.limit), 50);
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};

    if (params.keyword) {
      where.OR = [
        { title: { contains: params.keyword, mode: 'insensitive' } },
        { description: { contains: params.keyword, mode: 'insensitive' } },
        { tags: { has: params.keyword } },
      ];
    }

    if (params.prefectureCode) {
      const pref = await prisma.prefecture.findUnique({
        where: { code: params.prefectureCode },
      });
      if (pref) where.prefectureId = pref.id;
    }

    if (params.municipalityCode) {
      const muni = await prisma.municipality.findUnique({
        where: { code: params.municipalityCode },
      });
      if (muni) where.municipalityId = muni.id;
    }

    if (params.categoryId) where.categoryId = parseInt(params.categoryId);
    if (params.status) where.status = params.status;
    if (params.targetAudience) {
      where.targetAudience = { has: params.targetAudience };
    }
    if (params.isNational !== undefined) {
      where.isNational = params.isNational === 'true';
    }
    if (params.deadlineBefore) {
      where.applicationEnd = { lte: new Date(params.deadlineBefore) };
    }

    const orderBy: Record<string, string> =
      params.sortBy === 'deadline'
        ? { applicationEnd: 'asc' }
        : params.sortBy === 'amount'
        ? { maxAmount: 'desc' }
        : { announcedAt: 'desc' };

    const [subsidies, total] = await Promise.all([
      prisma.subsidy.findMany({
        where,
        include: {
          category: true,
          prefecture: { select: { code: true, name: true } },
          municipality: { select: { code: true, name: true } },
        },
        orderBy,
        skip,
        take: limit,
      }),
      prisma.subsidy.count({ where }),
    ]);

    res.json({
      data: subsidies,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/subsidies/stats - 統計情報
router.get('/stats', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const [total, active, endingSoon, byCategory] = await Promise.all([
      prisma.subsidy.count(),
      prisma.subsidy.count({ where: { status: 'ACTIVE' } }),
      prisma.subsidy.count({
        where: {
          status: 'ACTIVE',
          applicationEnd: {
            gte: new Date(),
            lte: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          },
        },
      }),
      prisma.subsidy.groupBy({
        by: ['categoryId'],
        _count: true,
        where: { status: 'ACTIVE' },
      }),
    ]);

    res.json({ total, active, endingSoon, byCategory });
  } catch (err) {
    next(err);
  }
});

// GET /api/subsidies/:id - 補助金詳細
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const subsidy = await prisma.subsidy.findUnique({
      where: { id: parseInt(req.params.id) },
      include: {
        category: true,
        prefecture: true,
        municipality: { include: { prefecture: true } },
      },
    });
    if (!subsidy) throw new AppError(404, '補助金情報が見つかりません');
    res.json(subsidy);
  } catch (err) {
    next(err);
  }
});

export default router;
