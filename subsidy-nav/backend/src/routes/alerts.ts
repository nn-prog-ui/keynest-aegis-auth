import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import crypto from 'crypto';
import { sendVerificationEmail } from '../services/emailService';

const router = Router();
const prisma = new PrismaClient();

router.post('/', async (req: Request, res: Response) => {
  try {
    const { email, prefectureCodes, municipalityCodes, audiences, categorySlugs } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const existing = await prisma.alertPreference.findFirst({ where: { email, isActive: true } });
    if (existing) {
      await prisma.alertPreference.update({
        where: { id: existing.id },
        data: { prefectureCodes, municipalityCodes, audiences, categorySlugs, verificationToken: token, tokenExpiresAt: expiresAt, isVerified: false },
      });
    } else {
      await prisma.alertPreference.create({
        data: { email, prefectureCodes: prefectureCodes || [], municipalityCodes: municipalityCodes || [], audiences: audiences || [], categorySlugs: categorySlugs || [], verificationToken: token, tokenExpiresAt: expiresAt },
      });
    }

    await sendVerificationEmail(email, token);
    res.json({ message: 'Verification email sent' });
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/verify/:token', async (req: Request, res: Response) => {
  try {
    const alert = await prisma.alertPreference.findFirst({
      where: { verificationToken: req.params.token, tokenExpiresAt: { gt: new Date() } },
    });
    if (!alert) return res.status(400).json({ error: 'Invalid or expired token' });

    await prisma.alertPreference.update({
      where: { id: alert.id },
      data: { isVerified: true, verificationToken: null, tokenExpiresAt: null },
    });

    res.redirect(`${process.env.FRONTEND_URL}/alerts?verified=true`);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:email', async (req: Request, res: Response) => {
  try {
    await prisma.alertPreference.updateMany({
      where: { email: req.params.email },
      data: { isActive: false },
    });
    res.json({ message: 'Unsubscribed' });
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
