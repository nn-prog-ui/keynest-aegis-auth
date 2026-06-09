import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

router.get('/stats', async (_req: Request, res: Response) => {
  try {
    const [subsidyCount, alertCount, inquiryCount, recentLogs] = await Promise.all([
      prisma.subsidy.count({ where: { status: 'ACTIVE' } }),
      prisma.alertPreference.count({ where: { isActive: true, isVerified: true } }),
      prisma.consultingInquiry.count({ where: { status: 'NEW' } }),
      prisma.scrapeLog.findMany({ orderBy: { createdAt: 'desc' }, take: 10, include: { municipality: true } }),
    ]);
    res.json({ subsidyCount, alertCount, inquiryCount, recentLogs });
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/subsidies', async (req: Request, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = 50;
    const [subsidies, total] = await Promise.all([
      prisma.subsidy.findMany({ skip: (page - 1) * limit, take: limit, include: { municipality: true, category: true }, orderBy: { createdAt: 'desc' } }),
      prisma.subsidy.count(),
    ]);
    res.json({ subsidies, total });
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/subsidies/:id', async (req: Request, res: Response) => {
  try {
    const subsidy = await prisma.subsidy.update({ where: { id: parseInt(req.params.id) }, data: req.body });
    res.json(subsidy);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/subsidies/:id', async (req: Request, res: Response) => {
  try {
    await prisma.subsidy.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Deleted' });
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/inquiries', async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string;
    const where = status ? { status: status as 'NEW' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED' } : {};
    const inquiries = await prisma.consultingInquiry.findMany({ where, orderBy: { createdAt: 'desc' } });
    res.json(inquiries);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/inquiries/:id', async (req: Request, res: Response) => {
  try {
    const inquiry = await prisma.consultingInquiry.update({ where: { id: parseInt(req.params.id) }, data: req.body });
    res.json(inquiry);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/scrape-logs', async (_req: Request, res: Response) => {
  try {
    const logs = await prisma.scrapeLog.findMany({ orderBy: { createdAt: 'desc' }, take: 50, include: { municipality: true } });
    res.json(logs);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
