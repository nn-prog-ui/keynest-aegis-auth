import Link from 'next/link';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

async function getStats() {
  try {
    const res = await fetch(`${API}/api/admin/stats`, { next: { revalidate: 60 }, cache: 'no-store' });
    if (!res.ok) return null;
    return res.json();
  } catch { return null; }
}

export default async function AdminPage() {
  const stats = await getStats();

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">管理ダッシュボード</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {[
          { label: '受付中の補助金', value: stats?.subsidyCount ?? '-', href: '/admin/subsidies', color: 'blue' },
          { label: 'アラート登録者', value: stats?.alertCount ?? '-', href: '/subsidies', color: 'green' },
          { label: '未対応お問い合わせ', value: stats?.inquiryCount ?? '-', href: '/admin/inquiries', color: 'orange' },
        ].map(s => (
          <Link key={s.label} href={s.href} className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md transition">
            <div className={`text-3xl font-bold text-${s.color}-600 mb-1`}>{s.value}</div>
            <div className="text-gray-600 text-sm">{s.label}</div>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        {[
          { label: '補助金管理', desc: '追加・編集・削除', href: '/admin/subsidies', icon: '📋' },
          { label: 'お問い合わせ管理', desc: '相談の確認・対応', href: '/admin/inquiries', icon: '💬' },
          { label: 'スクレイパー実行', desc: '手動でデータ収集', href: '/admin/scraper', icon: '🤖' },
        ].map(m => (
          <Link key={m.label} href={m.href} className="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition text-center">
            <div className="text-3xl mb-2">{m.icon}</div>
            <div className="font-semibold text-gray-800">{m.label}</div>
            <div className="text-sm text-gray-500">{m.desc}</div>
          </Link>
        ))}
      </div>

      {stats?.recentLogs?.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold text-gray-700 mb-4">最近のスクレイプログ</h2>
          <div className="space-y-2">
            {stats.recentLogs.slice(0, 5).map((log: { id: number; municipality: { name: string }; completedAt?: string; saved: number; success: boolean }) => (
              <div key={log.id} className="flex items-center gap-3 text-sm">
                <span className={`w-2 h-2 rounded-full ${log.success ? 'bg-green-400' : 'bg-red-400'}`} />
                <span className="text-gray-700 flex-1">{log.municipality.name}</span>
                <span className="text-gray-500">{log.saved}件保存</span>
                <span className="text-gray-400">{log.completedAt ? new Date(log.completedAt).toLocaleDateString('ja-JP') : '-'}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
