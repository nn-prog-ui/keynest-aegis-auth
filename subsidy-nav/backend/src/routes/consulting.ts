import { Router, Request, Response } from 'express';
import { PrismaClient, InquiryType } from '@prisma/client';

const router = Router();
const prisma = new PrismaClient();

router.post('/', async (req: Request, res: Response) => {
  try {
    const { name, company, email, phone, inquiryType, message } = req.body;
    if (!name || !email || !inquiryType || !message) {
      return res.status(400).json({ error: 'Required fields missing' });
    }

    const inquiry = await prisma.consultingInquiry.create({
      data: { name, company, email, phone, inquiryType: inquiryType as InquiryType, message },
    });

    res.status(201).json(inquiry);
  } catch {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
