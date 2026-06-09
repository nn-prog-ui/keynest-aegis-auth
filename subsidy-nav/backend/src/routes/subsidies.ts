import { Router, Request, Response } from 'express';
import { PrismaClient, SubsidyStatus, TargetAudience } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

router.get('/', async (req: Request, res: Response) => {
  try {
    const {
      page = '1',
      limit = '20',
      prefecture,
      municipality,
      category,
      audience,
      status = 'ACTIVE',
      keyword,
      isNational,
    } = req.query;

    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);
    const take = parseInt(limit as string);

    const where: Record<string, unknown> = {};

    if (status) where.status = status as SubsidyStatus;
    if (isNational === 'true') where.isNational = true;
    if (category) where.category = { slug: category };
    if (audience) where.targetAudiences = { has: audience as TargetAudience };
    if (keyword) {
      where.OR = [
        { title: { contains: keyword as string, mode: 'insensitive' } },
        { description: { contains: keyword as string, mode: 'insensitive' } },
      ];
    }
    if (municipality) {
      where.municipality = { code: municipality };
    } else if (prefecture) {
      where.municipality = { prefecture: { code: prefecture } };
    }

    const [subsidies, total] = await Promise.all([
      prisma.subsidy.findMany({
        where,
        skip,
        take,
        include: { municipality: { include: { prefecture: true } }, category: true },
        orderBy: { applicationEnd: 'asc' },
      }),
      prisma.subsidy.count({ where }),
    ]);

    res.json({ subsidies, total, page: parseInt(page as string), limit: take });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req: Request, res: Response) => {
  try {
    const subsidy = await prisma.subsidy.findUnique({
      where: { id: parseInt(req.params.id) },
      include: { municipality: { include: { prefecture: true } }, category: true },
    });
    if (!subsidy) return res.status(404).json({ error: 'Not found' });
    res.json(subsidy);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/meta/categories', async (_req: Request, res: Response) => {
  const categories = await prisma.subsidyCategory.findMany({ orderBy: { name: 'asc' } });
  res.json(categories);
});

router.get('/meta/prefectures', async (_req: Request, res: Response) => {
  const prefectures = await prisma.prefecture.findMany({ orderBy: { code: 'asc' } });
  res.json(prefectures);
});

export default router;
