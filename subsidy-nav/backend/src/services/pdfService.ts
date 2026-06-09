import PDFDocument from 'pdfkit';
import { Readable } from 'stream';

// フォントは標準のHelveticaを使用（日本語はUnicode文字として扱う）
// 本番では Noto Sans JP などの日本語フォントを別途登録推奨

interface SubsidyInfo {
  title: string;
  organization: string;
  maxAmount?: string;
  subsidyRate?: number;
  applicationEnd?: string;
  sourceUrl: string;
  requirements?: string;
  howToApply?: string;
}

interface ApplicantInfo {
  companyName?: string;
  representativeName: string;
  address: string;
  phone: string;
  email: string;
  businessDescription?: string;
  employeeCount?: number;
  established?: string;
}

interface ProjectInfo {
  title: string;
  purpose: string;
  period: string;
  totalCost: string;
  subsidyAmount: string;
  expectedEffect: string;
}

export type TemplateType =
  | 'general'       // 汎用補助金申請書
  | 'startup'       // 創業補助金申請書
  | 'it'            // IT導入補助金
  | 'wage_increase' // 業務改善助成金（賃上げ）
  | 'employment'    // 雇用・人材系助成金
  | 'housing'       // 住宅・省エネ補助金
  | 'agriculture';  // 農業補助金

function drawHr(doc: InstanceType<typeof PDFDocument>, y: number) {
  doc.moveTo(50, y).lineTo(545, y).strokeColor('#cccccc').lineWidth(0.5).stroke();
  doc.strokeColor('#000000').lineWidth(1);
}

function drawBox(
  doc: InstanceType<typeof PDFDocument>,
  x: number,
  y: number,
  w: number,
  h: number,
  fill = '#f8f9fa'
) {
  doc.rect(x, y, w, h).fillAndStroke(fill, '#cccccc');
  doc.fillColor('#000000');
}

function sectionTitle(doc: InstanceType<typeof PDFDocument>, text: string, y: number) {
  doc.rect(50, y, 495, 20).fill('#1a56db');
  doc.fillColor('#ffffff').fontSize(11).font('Helvetica-Bold').text(text, 55, y + 4);
  doc.fillColor('#000000').font('Helvetica').fontSize(10);
  return y + 28;
}

function labeledField(
  doc: InstanceType<typeof PDFDocument>,
  label: string,
  value: string,
  x: number,
  y: number,
  width = 220
) {
  doc.fontSize(8).fillColor('#666666').text(label, x, y);
  doc.fontSize(10).fillColor('#000000').text(value || '　', x, y + 12, { width });
  drawHr(doc, y + 28);
  return y + 36;
}

export async function generateTemplate(
  type: TemplateType,
  subsidy: SubsidyInfo,
  applicant: ApplicantInfo,
  project: ProjectInfo
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 50 });
    const chunks: Buffer[] = [];

    doc.on('data', (chunk: Buffer) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const today = new Date().toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });

    // ===== ヘッダー =====
    doc.rect(0, 0, 595, 80).fill('#1a3a6b');
    doc.fillColor('#ffffff').fontSize(18).font('Helvetica-Bold')
      .text(getTemplateTitle(type), 50, 20);
    doc.fontSize(10).font('Helvetica')
      .text(`提出日: ${today}`, 50, 48);
    doc.fillColor('#000000');

    let y = 100;

    // ===== 補助金情報ボックス =====
    drawBox(doc, 50, y, 495, 70, '#eff6ff');
    doc.fontSize(12).font('Helvetica-Bold').fillColor('#1a3a6b')
      .text(subsidy.title, 60, y + 8, { width: 480 });
    doc.font('Helvetica').fontSize(9).fillColor('#444444')
      .text(`実施機関: ${subsidy.organization}`, 60, y + 30);
    if (subsidy.maxAmount) {
      doc.text(`最大補助額: ${subsidy.maxAmount}`, 200, y + 30);
    }
    if (subsidy.applicationEnd) {
      doc.text(`申請締切: ${subsidy.applicationEnd}`, 380, y + 30);
    }
    doc.fillColor('#000000');
    y += 85;

    // ===== 申請者情報 =====
    y = sectionTitle(doc, '1. 申請者情報', y);
    const col1 = 50, col2 = 310;
    const fw = 220;

    doc.font('Helvetica').fontSize(10);
    if (applicant.companyName) {
      y = labeledField(doc, '法人名・屋号', applicant.companyName, col1, y, 470);
    }
    const nameY = y;
    labeledField(doc, '代表者氏名', applicant.representativeName, col1, nameY, fw);
    y = labeledField(doc, '従業員数', applicant.employeeCount ? `${applicant.employeeCount}名` : '', col2, nameY, fw);

    const addrY = y;
    labeledField(doc, '住所・所在地', applicant.address, col1, addrY, fw);
    y = labeledField(doc, '創業・設立年月', applicant.established || '', col2, addrY, fw);

    const phoneY = y;
    labeledField(doc, '電話番号', applicant.phone, col1, phoneY, fw);
    y = labeledField(doc, 'メールアドレス', applicant.email, col2, phoneY, fw);

    if (applicant.businessDescription) {
      doc.fontSize(8).fillColor('#666666').text('事業内容', col1, y);
      doc.fontSize(10).fillColor('#000000').text(applicant.businessDescription, col1, y + 12, { width: 470 });
      y += 12 + Math.max(30, doc.heightOfString(applicant.businessDescription, { width: 470 })) + 12;
      drawHr(doc, y - 4);
    }

    y += 16;

    // ===== 補助事業計画 =====
    y = sectionTitle(doc, '2. 補助事業計画', y);

    doc.fontSize(8).fillColor('#666666').text('事業タイトル', col1, y);
    doc.fontSize(11).font('Helvetica-Bold').fillColor('#000000').text(project.title, col1, y + 12, { width: 470 });
    y += 12 + 20 + 8;
    drawHr(doc, y - 4);

    const purposeY = y;
    doc.fontSize(8).fillColor('#666666').text('事業の目的・背景', col1, purposeY);
    doc.fontSize(10).font('Helvetica').fillColor('#000000')
      .text(project.purpose, col1, purposeY + 12, { width: 470 });
    y = purposeY + 12 + Math.max(40, doc.heightOfString(project.purpose, { width: 470 })) + 12;
    drawHr(doc, y - 4);
    y += 8;

    const periodY = y;
    labeledField(doc, '補助事業実施期間', project.period, col1, periodY, fw);
    y = labeledField(doc, '補助申請額', project.subsidyAmount, col2, periodY, fw);

    doc.fontSize(8).fillColor('#666666').text('総事業費', col1, y);
    doc.fontSize(10).fillColor('#000000').text(project.totalCost, col1, y + 12, { width: fw });
    y += 40;
    drawHr(doc, y - 4);
    y += 8;

    // 期待効果
    doc.fontSize(8).fillColor('#666666').text('期待される効果（数値目標）', col1, y);
    doc.fontSize(10).fillColor('#000000')
      .text(project.expectedEffect, col1, y + 12, { width: 470 });
    y += 12 + Math.max(40, doc.heightOfString(project.expectedEffect, { width: 470 })) + 16;
    drawHr(doc, y - 4);
    y += 16;

    // ===== テンプレート別追加セクション =====
    if (type === 'wage_increase') {
      y = sectionTitle(doc, '3. 賃金引上げ計画', y);
      const table = [
        ['項目', '引上げ前', '引上げ後', '引上げ額'],
        ['最低賃金（時給）', '　　円', '　　円', '　　円'],
        ['対象従業員数', '　　名', '　　名', '　　名'],
        ['設備投資内容', '─', '─', '─'],
      ];
      let ty = y + 4;
      table.forEach((row, ri) => {
        const colWidths = [140, 100, 100, 100];
        let tx = 50;
        row.forEach((cell, ci) => {
          const bg = ri === 0 ? '#e8f0fe' : ci === 0 ? '#f8f9fa' : '#ffffff';
          doc.rect(tx, ty, colWidths[ci], 20).fillAndStroke(bg, '#cccccc');
          doc.fillColor('#000000').fontSize(9).font(ri === 0 ? 'Helvetica-Bold' : 'Helvetica')
            .text(cell, tx + 4, ty + 5, { width: colWidths[ci] - 8 });
          tx += colWidths[ci];
        });
        ty += 20;
      });
      y = ty + 16;
    }

    if (type === 'employment') {
      y = sectionTitle(doc, '3. 雇用状況', y);
      const rows = [
        ['雇用形態', '現在人数', '転換・新規採用予定'],
        ['正社員', '', ''],
        ['有期雇用（パート・アルバイト）', '', ''],
        ['派遣社員', '', ''],
      ];
      let ty = y + 4;
      rows.forEach((row, ri) => {
        let tx = 50;
        [185, 155, 155].forEach((w, ci) => {
          const bg = ri === 0 ? '#e8f0fe' : ci === 0 ? '#f8f9fa' : '#ffffff';
          doc.rect(tx, ty, w, 20).fillAndStroke(bg, '#cccccc');
          doc.fillColor('#000000').fontSize(9).font(ri === 0 ? 'Helvetica-Bold' : 'Helvetica')
            .text(row[ci], tx + 4, ty + 5, { width: w - 8 });
          tx += w;
        });
        ty += 20;
      });
      y = ty + 16;
    }

    if (type === 'agriculture') {
      y = sectionTitle(doc, '3. 農業経営情報', y);
      const fields = [
        ['経営形態', ''],
        ['主要作目', ''],
        ['農地面積', '　　a（アール）'],
        ['認定農業者番号', ''],
      ];
      fields.forEach(([label, val]) => {
        y = labeledField(doc, label, val, col1, y, 470);
      });
    }

    // ===== 提出先・記載要領 =====
    if (y > 680) {
      doc.addPage();
      y = 50;
    }

    y = sectionTitle(doc, '【記載上の注意】', y);
    doc.fontSize(8).fillColor('#444444');
    const notes = [
      '・本様式は申請書の下書きです。実際の申請には各制度の公式様式をご使用ください。',
      '・数値目標は具体的に記載してください（例: 売上高〇%増、省エネ率〇%削減）。',
      '・添付書類（決算書・登記事項証明書・見積書等）の準備を忘れずに。',
      `・公式サイト: ${subsidy.sourceUrl}`,
    ];
    notes.forEach((note) => {
      doc.text(note, 55, y, { width: 485 });
      y += 14;
    });

    // ===== フッター =====
    doc.rect(0, 790, 595, 52).fill('#1a3a6b');
    doc.fillColor('#ffffff').fontSize(8)
      .text('補助金ナビ — 本書類は申請サポートの参考資料です。最終的な申請は公式窓口にてご確認ください。', 50, 802, {
        width: 495,
        align: 'center',
      });

    doc.end();
  });
}

function getTemplateTitle(type: TemplateType): string {
  const map: Record<TemplateType, string> = {
    general: '補助金申請書（汎用）',
    startup: '創業補助金 申請書',
    it: 'IT導入補助金 申請書',
    wage_increase: '業務改善助成金 申請書',
    employment: '雇用関連助成金 申請書',
    housing: '住宅・省エネ補助金 申請書',
    agriculture: '農業補助金 申請書',
  };
  return map[type];
}
