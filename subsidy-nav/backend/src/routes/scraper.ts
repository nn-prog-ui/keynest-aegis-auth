import { Router, Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { scrapeAll, scrapeMunicipality } from '../services/scraperService';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

// 管理者認証
function adminAuth(req: Request, _res: Response, next: NextFunction) {
  const key = req.headers['x-admin-key'];
  if (key !== process.env.API_SECRET_KEY) {
    return next(new AppError(401, '管理者権限が必要です'));
  }
  next();
}
router.use(adminAuth);

// POST /api/scraper/run-all - 全市区町村スクレイピング実行
router.post('/run-all', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    // 非同期で実行し、すぐに202を返す
    res.status(202).json({ message: 'スクレイピングを開始しました' });
    scrapeAll().then((result) => {
      console.log('[スクレイパー] 手動実行完了:', result);
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/scraper/logs - スクレイピングログ一覧
router.get('/logs', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const limit = parseInt(String(req.query.limit || 50));
    const logs = await prisma.scrapeLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    res.json(logs);
  } catch (err) {
    next(err);
  }
});

// GET /api/scraper/stats - スクレイピング統計
router.get('/stats', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const [total, success, error, lastRun] = await Promise.all([
      prisma.scrapeLog.count(),
      prisma.scrapeLog.count({ where: { status: 'SUCCESS' } }),
      prisma.scrapeLog.count({ where: { status: 'ERROR' } }),
      prisma.scrapeLog.findFirst({ orderBy: { createdAt: 'desc' } }),
    ]);

    const savedTotal = await prisma.scrapeLog.aggregate({
      _sum: { savedCount: true },
    });

    res.json({
      total,
      success,
      error,
      totalSaved: savedTotal._sum.savedCount ?? 0,
      lastRun: lastRun?.createdAt ?? null,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
