import { PrismaClient } from '@prisma/client';
import { CronJob } from 'node-cron';
import nodemailer from 'nodemailer';

const prisma = new PrismaClient();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

export async function sendWeeklyDigest(): Promise<{ sentCount: number; newSubsidies: number; endingSoon: number }> {
  const oneWeekAgo = new Date();
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
  const sevenDaysLater = new Date();
  sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);

  const [newSubsidies, endingSoon] = await Promise.all([
    prisma.subsidy.findMany({
      where: { createdAt: { gte: oneWeekAgo }, status: 'ACTIVE' },
      include: { municipality: { include: { prefecture: true } }, category: true },
      take: 20,
    }),
    prisma.subsidy.findMany({
      where: { status: 'ACTIVE', applicationEnd: { gte: new Date(), lte: sevenDaysLater } },
      include: { municipality: { include: { prefecture: true } } },
      take: 10,
    }),
  ]);

  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const adminEmail = process.env.ADMIN_EMAIL;

  if (!adminEmail) {
    console.log('[WeeklyDigest] ADMIN_EMAIL not set, skipping');
    return { sentCount: 0, newSubsidies: newSubsidies.length, endingSoon: endingSoon.length };
  }

  const newRows = newSubsidies.map(s => `
    <tr>
      <td><a href="${frontendUrl}/subsidies/${s.id}">${s.title}</a></td>
      <td>${s.municipality?.prefecture.name || '全国'}</td>
      <td>${s.category?.name || '-'}</td>
      <td>${s.applicationEnd ? s.applicationEnd.toLocaleDateString('ja-JP') : '随時'}</td>
    </tr>
  `).join('');

  const endingRows = endingSoon.map(s => `
    <tr>
      <td><a href="${frontendUrl}/subsidies/${s.id}">${s.title}</a></td>
      <td>${s.applicationEnd!.toLocaleDateString('ja-JP')}</td>
    </tr>
  `).join('');

  await transporter.sendMail({
    from: `"補助金ナビ" <${process.env.SMTP_USER}>`,
    to: adminEmail,
    subject: `【補助金ナビ】週次ダイジェスト - 新着${newSubsidies.length}件`,
    html: `
      <h1>補助金ナビ 週次ダイジェスト</h1>
      <h2>新着補助金（${newSubsidies.length}件）</h2>
      ${newSubsidies.length > 0 ? `
        <table border="1" cellpadding="8" style="border-collapse:collapse;width:100%">
          <thead><tr><th>補助金名</th><th>都道府県</th><th>カテゴリ</th><th>締切</th></tr></thead>
          <tbody>${newRows}</tbody>
        </table>
      ` : '<p>新着はありません</p>'}
      <h2>締切間近（${endingSoon.length}件）</h2>
      ${endingSoon.length > 0 ? `
        <table border="1" cellpadding="8" style="border-collapse:collapse;width:100%">
          <thead><tr><th>補助金名</th><th>締切日</th></tr></thead>
          <tbody>${endingRows}</tbody>
        </table>
      ` : '<p>締切間近の補助金はありません</p>'}
      <p><a href="${frontendUrl}/admin">管理画面を開く</a></p>
    `,
  });

  return { sentCount: 1, newSubsidies: newSubsidies.length, endingSoon: endingSoon.length };
}

export function startWeeklyDigestCron(): void {
  new CronJob('0 0 8 * * 1', async () => {
    console.log('[WeeklyDigest] Sending weekly digest...');
    const result = await sendWeeklyDigest();
    console.log(`[WeeklyDigest] Done: ${JSON.stringify(result)}`);
  }, null, true);
}
