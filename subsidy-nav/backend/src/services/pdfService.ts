import PDFDocument from 'pdfkit';

type TemplateType = 'general' | 'startup' | 'it' | 'wage_increase' | 'employment' | 'housing' | 'agriculture';

interface SubsidyInfo {
  title: string;
  maxAmount?: number;
  applicationEnd?: string;
}

interface ApplicantInfo {
  name: string;
  company?: string;
  address?: string;
  phone?: string;
  email?: string;
}

interface ProjectInfo {
  title: string;
  description: string;
  budget?: number;
  period?: string;
}

const TEMPLATE_TITLES: Record<TemplateType, string> = {
  general: '補助金申請書（汎用）',
  startup: '創業支援補助金申請書',
  it: 'IT導入補助金申請書',
  wage_increase: '賃上げ促進補助金申請書',
  employment: '雇用促進補助金申請書',
  housing: '住宅改修補助金申請書',
  agriculture: '農業振興補助金申請書',
};

export async function generateTemplate(
  type: TemplateType,
  subsidy: SubsidyInfo,
  applicant: ApplicantInfo,
  project: ProjectInfo,
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 50, size: 'A4' });
    const chunks: Buffer[] = [];

    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    doc.fontSize(18).text(TEMPLATE_TITLES[type] || '補助金申請書', { align: 'center' });
    doc.moveDown();
    doc.fontSize(14).text(`対象補助金: ${subsidy.title}`);
    if (subsidy.maxAmount) doc.fontSize(11).text(`補助上限額: ${subsidy.maxAmount.toLocaleString()}円`);
    if (subsidy.applicationEnd) doc.text(`申請期限: ${subsidy.applicationEnd}`);

    doc.moveDown();
    doc.fontSize(14).text('申請者情報');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(0.5);
    doc.fontSize(11)
      .text(`氏名／名称: ${applicant.name}`)
      .text(`会社名: ${applicant.company || '-'}`)
      .text(`住所: ${applicant.address || '-'}`)
      .text(`電話番号: ${applicant.phone || '-'}`)
      .text(`メールアドレス: ${applicant.email || '-'}`);

    doc.moveDown();
    doc.fontSize(14).text('事業計画');
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(0.5);
    doc.fontSize(11)
      .text(`事業名: ${project.title}`)
      .text(`事業概要:`)
      .text(project.description, { indent: 20 });
    if (project.budget) doc.text(`事業費: ${project.budget.toLocaleString()}円`);
    if (project.period) doc.text(`実施期間: ${project.period}`);

    doc.moveDown(2);
    doc.fontSize(11).text('上記の通り申請します。', { align: 'right' });
    doc.moveDown();
    doc.text(`申請日: ${new Date().toLocaleDateString('ja-JP')}`, { align: 'right' });
    doc.moveDown();
    doc.text('署名: ___________________________', { align: 'right' });

    doc.end();
  });
}
