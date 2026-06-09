import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PrismaClient, InquiryType } from '@prisma/client';
import { sendConsultingNotification } from '../services/notificationService';
import { AppError } from '../middleware/errorHandler';

const router = Router();
const prisma = new PrismaClient();

const InquirySchema = z.object({
  name: z.string().min(1, 'お名前を入力してください'),
  email: z.string().email('有効なメールアドレスを入力してください'),
  phone: z.string().optional(),
  companyName: z.string().optional(),
  inquiryType: z.nativeEnum(InquiryType),
  message: z.string().min(10, 'お問い合わせ内容を10文字以上で入力してください'),
});

// POST /api/consulting - コンサルティング問い合わせ
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = InquirySchema.parse(req.body);

    const inquiry = await prisma.consultingInquiry.create({ data });

    await sendConsultingNotification(inquiry);

    res.status(201).json({
      message: 'お問い合わせを受け付けました。2営業日以内にご連絡いたします。',
      id: inquiry.id,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return next(new AppError(400, err.errors[0].message));
    }
    next(err);
  }
});

export default router;
