import { Router, Request, Response } from 'express';
import { generateTemplate } from '../services/pdfService';

const router = Router();

router.post('/generate', async (req: Request, res: Response) => {
  try {
    const { templateType, subsidy, applicant, project } = req.body;
    const buffer = await generateTemplate(templateType, subsidy, applicant, project);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="subsidy-template-${templateType}.pdf"`,
      'Content-Length': buffer.length,
    });
    res.send(buffer);
  } catch {
    res.status(500).json({ error: 'PDF generation failed' });
  }
});

export default router;
