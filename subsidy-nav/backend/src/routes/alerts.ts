import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PrismaClient, TargetAudience } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';
import { sendAlertVerificationEmail } from '../services/notificationService';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

const AlertSchema = z.object({
  email: z.string().email('有効なメールアドレスを入力してください'),
  prefectureIds: z.array(z.number()).default([]),
  municipalityIds: z.array(z.number()).default([]),
  categoryIds: z.array(z.number()).default([]),
  targetAudiences: z.array(z.nativeEnum(TargetAudience)).default([]),
  notifyNewSubsidy: z.boolean().default(true),
  deadlineReminderDays: z.number().min(1).max(60).default(14),
});

// POST /api/alerts - アラート登録
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = AlertSchema.parse(req.body);
    const verifyToken = uuidv4();

    const alert = await prisma.alertPreference.create({
      data: {
        ...data,
        verifyToken,
        isVerified: false,
      },
    });

    await sendAlertVerificationEmail(data.email, verifyToken);

    res.status(201).json({
      message: '確認メールを送信しました。メールのリンクをクリックして登録を完了してください。',
      id: alert.id,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return next(new AppError(400, err.errors[0].message));
    }
    next(err);
  }
});

// GET /api/alerts/verify/:token - メール確認
router.get('/verify/:token', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const alert = await prisma.alertPreference.findUnique({
      where: { verifyToken: req.params.token },
    });
    if (!alert) throw new AppError(404, '無効または期限切れのトークンです');

    await prisma.alertPreference.update({
      where: { id: alert.id },
      data: { isVerified: true, verifyToken: null },
    });

    res.json({ message: 'アラート設定が完了しました！補助金情報をお届けします。' });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/alerts/:id - アラート解除
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await prisma.alertPreference.delete({
      where: { id: parseInt(req.params.id) },
    });
    res.json({ message: 'アラートを解除しました' });
  } catch (err) {
    next(err);
  }
});

export default router;
