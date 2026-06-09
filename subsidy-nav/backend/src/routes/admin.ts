import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PrismaClient, SubsidyStatus, TargetAudience } from '@prisma/client';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

// 簡易管理者認証ミドルウェア
function adminAuth(req: Request, _res: Response, next: NextFunction) {
  const key = req.headers['x-admin-key'];
  if (key !== process.env.API_SECRET_KEY) {
    return next(new AppError(401, '管理者権限が必要です'));
  }
  next();
}
router.use(adminAuth);

const SubsidyCreateSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  detail: z.string().optional(),
  categoryId: z.number(),
  prefectureId: z.number().optional(),
  municipalityId: z.number().optional(),
  isNational: z.boolean().default(false),
  maxAmount: z.number().optional(),
  subsidyRate: z.number().min(0).max(1).optional(),
  targetAudience: z.array(z.nativeEnum(TargetAudience)).default([]),
  applicationStart: z.string().optional(),
  applicationEnd: z.string().optional(),
  sourceUrl: z.string().url(),
  status: z.nativeEnum(SubsidyStatus).default('ACTIVE'),
  tags: z.array(z.string()).default([]),
  requirements: z.string().optional(),
  howToApply: z.string().optional(),
});

// GET /api/admin/subsidies - 全補助金一覧
router.get('/subsidies', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const subsidies = await prisma.subsidy.findMany({
      include: { category: true, prefecture: true, municipality: true },
      orderBy: { announcedAt: 'desc' },
    });
    res.json(subsidies);
  } catch (err) {
    next(err);
  }
});

// POST /api/admin/subsidies - 補助金登録
router.post('/subsidies', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = SubsidyCreateSchema.parse(req.body);
    const subsidy = await prisma.subsidy.create({
      data: {
        ...data,
        maxAmount: data.maxAmount ? BigInt(data.maxAmount) : undefined,
        applicationStart: data.applicationStart
          ? new Date(data.applicationStart)
          : undefined,
        applicationEnd: data.applicationEnd
          ? new Date(data.applicationEnd)
          : undefined,
      },
    });
    res.status(201).json(subsidy);
  } catch (err) {
    if (err instanceof z.ZodError) {
      return next(new AppError(400, err.errors[0].message));
    }
    next(err);
  }
});

// PUT /api/admin/subsidies/:id - 補助金更新
router.put('/subsidies/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = SubsidyCreateSchema.partial().parse(req.body);
    const subsidy = await prisma.subsidy.update({
      where: { id: parseInt(req.params.id) },
      data: {
        ...data,
        maxAmount: data.maxAmount ? BigInt(data.maxAmount) : undefined,
        applicationStart: data.applicationStart
          ? new Date(data.applicationStart)
          : undefined,
        applicationEnd: data.applicationEnd
          ? new Date(data.applicationEnd)
          : undefined,
      },
    });
    res.json(subsidy);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/admin/subsidies/:id - 補助金削除
router.delete('/subsidies/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await prisma.subsidy.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: '削除しました' });
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/inquiries - 問い合わせ一覧
router.get('/inquiries', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const inquiries = await prisma.consultingInquiry.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json(inquiries);
  } catch (err) {
    next(err);
  }
});

// GET /api/admin/alerts - アラート登録者一覧
router.get('/alerts', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const alerts = await prisma.alertPreference.findMany({
      where: { isVerified: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(alerts);
  } catch (err) {
    next(err);
  }
});

export default router;
