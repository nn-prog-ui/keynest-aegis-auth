import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export async function sendVerificationEmail(email: string, token: string): Promise<void> {
  const verifyUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/api/alerts/verify/${token}`;
  await transporter.sendMail({
    from: `"補助金ナビ" <${process.env.SMTP_USER}>`,
    to: email,
    subject: '【補助金ナビ】メールアドレスの確認',
    html: `
      <h2>補助金アラートの登録確認</h2>
      <p>以下のリンクをクリックして、メールアドレスを確認してください。</p>
      <a href="${verifyUrl}" style="background:#2563eb;color:white;padding:12px 24px;text-decoration:none;border-radius:6px;display:inline-block;">
        メールアドレスを確認する
      </a>
      <p>このリンクは24時間有効です。</p>
    `,
  });
}

export async function sendDeadlineAlert(email: string, subsidies: Array<{ title: string; applicationEnd: Date; id: number }>): Promise<void> {
  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const rows = subsidies.map(s => `
    <tr>
      <td><a href="${frontendUrl}/subsidies/${s.id}">${s.title}</a></td>
      <td>${s.applicationEnd.toLocaleDateString('ja-JP')}</td>
    </tr>
  `).join('');

  await transporter.sendMail({
    from: `"補助金ナビ" <${process.env.SMTP_USER}>`,
    to: email,
    subject: '【補助金ナビ】締切間近の補助金があります',
    html: `
      <h2>締切間近の補助金</h2>
      <table border="1" cellpadding="8" style="border-collapse:collapse;width:100%">
        <thead><tr><th>補助金名</th><th>締切日</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
      <p><a href="${frontendUrl}/subsidies">補助金一覧を見る</a></p>
    `,
  });
}
