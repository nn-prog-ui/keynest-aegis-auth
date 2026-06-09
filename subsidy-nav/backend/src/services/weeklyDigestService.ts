import nodemailer from 'nodemailer';
import { PrismaClient } from '@prisma/client';
import { CronJob } from 'cron';

const prisma = new PrismaClient();

function createTransporter() {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
  });
}

interface DigestSubsidy {
  id: number;
  title: string;
  description: string;
  maxAmount: bigint | null;
  applicationEnd: Date | null;
  status: string;
  isNational: boolean;
  category: { name: string; icon: string };
  prefecture: { name: string } | null;
  municipality: { name: string } | null;
  announcedAt: Date;
}

function formatAmount(amount: bigint): string {
  const n = Number(amount);
  if (n >= 100_000_000) return `${Math.round(n / 100_000_000)}億円`;
  if (n >= 10_000) return `${Math.round(n / 10_000)}万円`;
  return `${n.toLocaleString()}円`;
}

function buildSubsidyRows(subsidies: DigestSubsidy[], frontendUrl: string): string {
  return subsidies
    .map((s) => {
      const area = s.isNational
        ? '全国'
        : s.municipality?.name || s.prefecture?.name || '—';
      const amount = s.maxAmount ? `最大${formatAmount(s.maxAmount)}` : '—';
      const deadline = s.applicationEnd
        ? s.applicationEnd.toLocaleDateString('ja-JP', { month: 'long', day: 'numeric' }) + '締切'
        : '期限未定';
      const isUrgent =
        s.applicationEnd &&
        s.applicationEnd.getTime() - Date.now() < 14 * 24 * 60 * 60 * 1000;

      return `
        <tr>
          <td style="padding:12px 8px; border-bottom:1px solid #eee; vertical-align:top;">
            <span style="font-size:11px; color:#1a56db; font-weight:600;">${s.category.icon} ${s.category.name}</span><br>
            <a href="${frontendUrl}/subsidies/${s.id}" style="color:#111; font-weight:700; text-decoration:none; font-size:13px;">${s.title}</a><br>
            <span style="font-size:12px; color:#666;">${s.description.slice(0, 80)}…</span>
          </td>
          <td style="padding:12px 8px; border-bottom:1px solid #eee; white-space:nowrap; font-size:12px; color:#555; vertical-align:top;">${area}</td>
          <td style="padding:12px 8px; border-bottom:1px solid #eee; white-space:nowrap; font-weight:700; color:#1a56db; font-size:13px; vertical-align:top;">${amount}</td>
          <td style="padding:12px 8px; border-bottom:1px solid #eee; white-space:nowrap; font-size:12px; vertical-align:top;">
            <span style="color:${isUrgent ? '#dc2626' : '#555'}; font-weight:${isUrgent ? '700' : '400'};">${deadline}</span>
          </td>
        </tr>`;
    })
    .join('');
}

function buildDigestHtml(params: {
  recipientName: string;
  newSubsidies: DigestSubsidy[];
  endingSoon: DigestSubsidy[];
  stats: { totalNew: number; totalActive: number; totalEndingSoon: number };
  weekOf: string;
  frontendUrl: string;
  isAdmin: boolean;
}): string {
  const { recipientName, newSubsidies, endingSoon, stats, weekOf, frontendUrl, isAdmin } = params;

  return `<!DOCTYPE html>
<html lang="ja">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:'Helvetica Neue',Arial,sans-serif;">
<div style="max-width:640px;margin:24px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,0.08);">

  <!-- ヘッダー -->
  <div style="background:linear-gradient(135deg,#1e40af,#2563eb);padding:32px 32px 24px;">
    <div style="color:#93c5fd;font-size:12px;margin-bottom:4px;">${weekOf} 週次レポート</div>
    <h1 style="color:#fff;margin:0;font-size:22px;">補助金ナビ 週次ダイジェスト</h1>
    ${isAdmin ? '<div style="margin-top:8px;background:rgba(255,255,255,0.15);display:inline-block;padding:2px 10px;border-radius:20px;color:#fde68a;font-size:11px;">管理者レポート</div>' : ''}
  </div>

  <!-- サマリー数値 -->
  <div style="display:flex;padding:0;border-bottom:1px solid #eee;">
    ${[
      { label: '今週の新着', value: stats.totalNew, color: '#2563eb' },
      { label: '現在受付中', value: stats.totalActive, color: '#059669' },
      { label: '2週間以内締切', value: stats.totalEndingSoon, color: '#dc2626' },
    ]
      .map(
        (s) => `
      <div style="flex:1;padding:20px 12px;text-align:center;border-right:1px solid #eee;">
        <div style="font-size:28px;font-weight:800;color:${s.color};">${s.value}</div>
        <div style="font-size:11px;color:#888;margin-top:2px;">${s.label}</div>
      </div>`
      )
      .join('')}
  </div>

  <div style="padding:24px 32px;">

    <!-- 今週の新着 -->
    ${
      newSubsidies.length > 0
        ? `
    <h2 style="font-size:16px;color:#111;margin:0 0 12px;padding-bottom:8px;border-bottom:2px solid #2563eb;">
      🆕 今週の新着補助金 (${newSubsidies.length}件)
    </h2>
    <table style="width:100%;border-collapse:collapse;margin-bottom:24px;">
      <thead>
        <tr style="background:#f0f4ff;">
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">補助金名</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">地域</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">金額</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">締切</th>
        </tr>
      </thead>
      <tbody>${buildSubsidyRows(newSubsidies, frontendUrl)}</tbody>
    </table>`
        : '<p style="color:#888;font-size:13px;">今週の新着補助金はありません。</p>'
    }

    <!-- 締切間近 -->
    ${
      endingSoon.length > 0
        ? `
    <h2 style="font-size:16px;color:#dc2626;margin:0 0 12px;padding-bottom:8px;border-bottom:2px solid #dc2626;">
      ⚠️ 締切間近の補助金（2週間以内）
    </h2>
    <table style="width:100%;border-collapse:collapse;margin-bottom:24px;">
      <thead>
        <tr style="background:#fff5f5;">
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">補助金名</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">地域</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">金額</th>
          <th style="padding:8px;text-align:left;font-size:12px;color:#555;">締切</th>
        </tr>
      </thead>
      <tbody>${buildSubsidyRows(endingSoon, frontendUrl)}</tbody>
    </table>`
        : ''
    }

    <!-- CTA -->
    <div style="text-align:center;margin-top:16px;">
      <a href="${frontendUrl}/subsidies?sortBy=newest" style="display:inline-block;background:#2563eb;color:#fff;padding:12px 28px;border-radius:8px;font-weight:700;text-decoration:none;font-size:14px;">全ての補助金を確認する →</a>
    </div>

    <!-- アンサブ -->
    <p style="font-size:11px;color:#aaa;text-align:center;margin-top:28px;padding-top:16px;border-top:1px solid #eee;">
      このメールは補助金ナビの週次ダイジェストです。<br>
      配信停止はお住まいの自治体の補助金ナビ設定ページから行えます。
    </p>
  </div>
</div>
</body>
</html>`;
}

export async function sendWeeklyDigest(): Promise<{
  sentCount: number;
  newSubsidies: number;
  endingSoon: number;
}> {
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const adminEmail = process.env.ADMIN_EMAIL || process.env.SMTP_USER || '';
  const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const twoWeeksLater = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);

  const weekOf = new Date().toLocaleDateString('ja-JP', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  // 今週の新着・締切間近を取得
  const [newSubsidies, endingSoon, totalActive] = await Promise.all([
    prisma.subsidy.findMany({
      where: { announcedAt: { gte: oneWeekAgo } },
      include: {
        category: true,
        prefecture: { select: { name: true } },
        municipality: { select: { name: true } },
      },
      orderBy: { announcedAt: 'desc' },
      take: 20,
    }),
    prisma.subsidy.findMany({
      where: {
        status: 'ACTIVE',
        applicationEnd: { gte: new Date(), lte: twoWeeksLater },
      },
      include: {
        category: true,
        prefecture: { select: { name: true } },
        municipality: { select: { name: true } },
      },
      orderBy: { applicationEnd: 'asc' },
      take: 10,
    }),
    prisma.subsidy.count({ where: { status: 'ACTIVE' } }),
  ]);

  const stats = {
    totalNew: newSubsidies.length,
    totalActive,
    totalEndingSoon: endingSoon.length,
  };

  const transporter = createTransporter();
  let sentCount = 0;

  // 1. 管理者へ送信
  if (adminEmail) {
    const html = buildDigestHtml({
      recipientName: '管理者',
      newSubsidies: newSubsidies as DigestSubsidy[],
      endingSoon: endingSoon as DigestSubsidy[],
      stats,
      weekOf,
      frontendUrl,
      isAdmin: true,
    });

    await transporter.sendMail({
      from: process.env.MAIL_FROM,
      to: adminEmail,
      subject: `【補助金ナビ 管理者レポート】${weekOf} — 新着${stats.totalNew}件・締切間近${stats.totalEndingSoon}件`,
      html,
    });
    sentCount++;
    console.log(`[週次ダイジェスト] 管理者(${adminEmail})へ送信完了`);
  }

  // 2. アラート登録者へ送信（設定条件に合う補助金のみ絞り込み）
  const alerts = await prisma.alertPreference.findMany({
    where: { isVerified: true },
  });

  for (const alert of alerts) {
    // アラート設定に合う新着補助金を絞り込み
    const filtered = newSubsidies.filter((s) => {
      if (alert.prefectureIds.length > 0 && s.prefectureId) {
        if (!alert.prefectureIds.includes(s.prefectureId) && !s.isNational) return false;
      }
      if (alert.categoryIds.length > 0) {
        if (!alert.categoryIds.includes(s.categoryId)) return false;
      }
      return true;
    });

    // 新着または締切間近がある場合のみ送信
    if (filtered.length === 0 && endingSoon.length === 0) continue;

    const html = buildDigestHtml({
      recipientName: alert.email.split('@')[0],
      newSubsidies: filtered as DigestSubsidy[],
      endingSoon: endingSoon as DigestSubsidy[],
      stats: { ...stats, totalNew: filtered.length },
      weekOf,
      frontendUrl,
      isAdmin: false,
    });

    try {
      await transporter.sendMail({
        from: process.env.MAIL_FROM,
        to: alert.email,
        subject: `【補助金ナビ】${weekOf}の新着補助金${filtered.length}件をお届けします`,
        html,
      });
      sentCount++;
    } catch (err) {
      console.error(`[週次ダイジェスト] ${alert.email} への送信エラー:`, err);
    }
  }

  console.log(`[週次ダイジェスト] 合計 ${sentCount} 件送信完了`);
  return { sentCount, newSubsidies: newSubsidies.length, endingSoon: endingSoon.length };
}

// 毎週月曜日 朝8時に週次ダイジェストを送信
export function startWeeklyDigestCron() {
  // cron書式: 秒 分 時 日 月 曜日 (0=日曜, 1=月曜)
  const job = new CronJob('0 0 8 * * 1', async () => {
    console.log('[週次ダイジェスト] 送信開始...');
    try {
      const result = await sendWeeklyDigest();
      console.log(
        `[週次ダイジェスト] 完了: 新着${result.newSubsidies}件 / 締切間近${result.endingSoon}件 / 送信${result.sentCount}件`
      );
    } catch (err) {
      console.error('[週次ダイジェスト] エラー:', err);
    }
  });
  job.start();
  console.log('週次ダイジェストCronジョブ開始 (毎週月曜 08:00)');
}
