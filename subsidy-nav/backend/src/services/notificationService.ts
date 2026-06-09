import nodemailer from 'nodemailer';
import { CronJob } from 'cron';
import { PrismaClient, ConsultingInquiry } from '@prisma/client';

const prisma = new PrismaClient();

function createTransporter() {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

export async function sendAlertVerificationEmail(email: string, token: string) {
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const verifyUrl = `${frontendUrl}/alerts/verify/${token}`;

  const transporter = createTransporter();
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: email,
    subject: '【補助金ナビ】メールアドレス確認のお願い',
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #1a56db;">補助金ナビ アラート登録確認</h2>
        <p>以下のボタンをクリックして、アラート登録を完了してください。</p>
        <a href="${verifyUrl}" style="
          display: inline-block;
          background: #1a56db;
          color: white;
          padding: 12px 24px;
          border-radius: 6px;
          text-decoration: none;
          font-weight: bold;
        ">メールアドレスを確認する</a>
        <p style="color: #666; font-size: 12px; margin-top: 24px;">
          このリンクに心当たりがない場合は、このメールを無視してください。
        </p>
      </div>
    `,
  });
}

export async function sendSubsidyAlertEmail(
  email: string,
  subsidies: Array<{ title: string; applicationEnd: Date | null; id: number }>
) {
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const items = subsidies
    .map(
      (s) => `
      <tr>
        <td style="padding: 8px; border-bottom: 1px solid #eee;">
          <a href="${frontendUrl}/subsidies/${s.id}" style="color: #1a56db; font-weight: bold;">${s.title}</a>
        </td>
        <td style="padding: 8px; border-bottom: 1px solid #eee; color: #e11d48;">
          ${s.applicationEnd ? `締切: ${s.applicationEnd.toLocaleDateString('ja-JP')}` : '締切未定'}
        </td>
      </tr>`
    )
    .join('');

  const transporter = createTransporter();
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: email,
    subject: `【補助金ナビ】${subsidies.length}件の補助金情報をお知らせします`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #1a56db;">新着・締切間近の補助金情報</h2>
        <table style="width: 100%; border-collapse: collapse;">
          <thead>
            <tr style="background: #f3f4f6;">
              <th style="padding: 8px; text-align: left;">補助金名</th>
              <th style="padding: 8px; text-align: left;">締切</th>
            </tr>
          </thead>
          <tbody>${items}</tbody>
        </table>
        <p style="margin-top: 16px;">
          <a href="${frontendUrl}/subsidies" style="color: #1a56db;">すべての補助金を見る →</a>
        </p>
        <p style="color: #666; font-size: 12px; margin-top: 24px;">
          アラートを解除する場合は設定ページからお手続きください。
        </p>
      </div>
    `,
  });
}

export async function sendConsultingNotification(inquiry: ConsultingInquiry) {
  const typeLabels: Record<string, string> = {
    SUBSIDY_SEARCH: '補助金・助成金の探し方',
    APPLICATION_HELP: '申請サポート',
    CONSULTING: '事業コンサルティング',
    OTHER: 'その他',
  };

  const transporter = createTransporter();
  // 担当者へ通知
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: process.env.SMTP_USER,
    subject: `【補助金ナビ】新規お問い合わせ: ${typeLabels[inquiry.inquiryType]}`,
    html: `
      <h3>新規お問い合わせが届きました</h3>
      <table>
        <tr><th>お名前</th><td>${inquiry.name}</td></tr>
        <tr><th>メール</th><td>${inquiry.email}</td></tr>
        <tr><th>電話</th><td>${inquiry.phone || '未記入'}</td></tr>
        <tr><th>会社名</th><td>${inquiry.companyName || '未記入'}</td></tr>
        <tr><th>種類</th><td>${typeLabels[inquiry.inquiryType]}</td></tr>
        <tr><th>内容</th><td>${inquiry.message}</td></tr>
      </table>
    `,
  });

  // ユーザーへ自動返信
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: inquiry.email,
    subject: '【補助金ナビ】お問い合わせを受け付けました',
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #1a56db;">お問い合わせありがとうございます</h2>
        <p>${inquiry.name} 様</p>
        <p>お問い合わせを受け付けました。<br>2営業日以内に担当者よりご連絡いたします。</p>
        <p style="margin-top: 24px;">補助金ナビ コンサルティング事業部</p>
      </div>
    `,
  });
}

// 毎日朝8時に締切通知を送信
export function startDeadlineNotificationCron() {
  const job = new CronJob('0 8 * * *', async () => {
    console.log('締切通知チェック実行中...');
    try {
      const alerts = await prisma.alertPreference.findMany({
        where: { isVerified: true },
      });

      for (const alert of alerts) {
        const deadlineDate = new Date(
          Date.now() + alert.deadlineReminderDays * 24 * 60 * 60 * 1000
        );

        const where: Record<string, unknown> = {
          status: 'ACTIVE',
          applicationEnd: { lte: deadlineDate, gte: new Date() },
        };

        if (alert.prefectureIds.length > 0) {
          where.prefectureId = { in: alert.prefectureIds };
        }
        if (alert.municipalityIds.length > 0) {
          where.municipalityId = { in: alert.municipalityIds };
        }
        if (alert.categoryIds.length > 0) {
          where.categoryId = { in: alert.categoryIds };
        }

        const subsidies = await prisma.subsidy.findMany({
          where,
          select: { id: true, title: true, applicationEnd: true },
          take: 10,
        });

        if (subsidies.length > 0) {
          await sendSubsidyAlertEmail(alert.email, subsidies);
        }
      }
    } catch (err) {
      console.error('締切通知エラー:', err);
    }
  });

  job.start();
  console.log('締切通知Cronジョブ開始 (毎日 08:00)');
}
