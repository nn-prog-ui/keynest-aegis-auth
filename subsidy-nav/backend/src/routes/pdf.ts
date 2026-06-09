import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { generateTemplate, TemplateType } from '../services/pdfService';
import { AppError } from '../middleware/errorHandler';

const router = Router();

const GenerateSchema = z.object({
  templateType: z.enum(['general', 'startup', 'it', 'wage_increase', 'employment', 'housing', 'agriculture']),
  subsidy: z.object({
    title: z.string(),
    organization: z.string(),
    maxAmount: z.string().optional(),
    subsidyRate: z.number().optional(),
    applicationEnd: z.string().optional(),
    sourceUrl: z.string(),
    requirements: z.string().optional(),
    howToApply: z.string().optional(),
  }),
  applicant: z.object({
    companyName: z.string().optional(),
    representativeName: z.string(),
    address: z.string(),
    phone: z.string(),
    email: z.string(),
    businessDescription: z.string().optional(),
    employeeCount: z.number().optional(),
    established: z.string().optional(),
  }),
  project: z.object({
    title: z.string(),
    purpose: z.string(),
    period: z.string(),
    totalCost: z.string(),
    subsidyAmount: z.string(),
    expectedEffect: z.string(),
  }),
});

// POST /api/pdf/generate - PDF生成・ダウンロード
router.post('/generate', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { templateType, subsidy, applicant, project } = GenerateSchema.parse(req.body);

    const pdfBuffer = await generateTemplate(
      templateType as TemplateType,
      subsidy,
      applicant,
      project
    );

    const filename = `hojokin-shinsei-${templateType}-${Date.now()}.pdf`;
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': pdfBuffer.length,
    });
    res.send(pdfBuffer);
  } catch (err) {
    if (err instanceof z.ZodError) {
      return next(new AppError(400, err.errors[0].message));
    }
    next(err);
  }
});

// GET /api/pdf/templates - テンプレート一覧
router.get('/templates', (_req: Request, res: Response) => {
  res.json([
    {
      type: 'general',
      name: '汎用補助金申請書',
      description: 'どの補助金にも使える汎用テンプレート',
      icon: '📄',
      categories: ['全カテゴリ'],
    },
    {
      type: 'startup',
      name: '創業補助金申請書',
      description: '創業・起業時の補助金申請に特化したテンプレート',
      icon: '🚀',
      categories: ['創業・事業拡大'],
    },
    {
      type: 'it',
      name: 'IT導入補助金申請書',
      description: 'ITツール・システム導入補助金の申請テンプレート',
      icon: '💻',
      categories: ['IT・デジタル化'],
    },
    {
      type: 'wage_increase',
      name: '業務改善助成金申請書',
      description: '賃上げ+設備投資の助成金申請テンプレート',
      icon: '💰',
      categories: ['雇用・人材'],
    },
    {
      type: 'employment',
      name: '雇用関連助成金申請書',
      description: 'キャリアアップ・人材確保等の助成金申請テンプレート',
      icon: '👥',
      categories: ['雇用・人材'],
    },
    {
      type: 'housing',
      name: '住宅・省エネ補助金申請書',
      description: 'ZEH・窓リノベ・給湯器交換等の補助金申請テンプレート',
      icon: '🏠',
      categories: ['住宅・リフォーム', '省エネ・環境'],
    },
    {
      type: 'agriculture',
      name: '農業補助金申請書',
      description: '農機具導入・有機農業等の補助金申請テンプレート',
      icon: '🌾',
      categories: ['農業・林業・水産業'],
    },
  ]);
});

export default router;
