'use client';
import { useEffect, useState } from 'react';

interface Subsidy {
  id: number;
  title: string;
  status: string;
  isNational: boolean;
  applicationEnd?: string;
  municipality?: { name: string };
  category?: { name: string };
}

export default function AdminSubsidiesPage() {
  const [subsidies, setSubsidies] = useState<Subsidy[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/subsidies')
      .then(r => r.json())
      .then(d => { setSubsidies(d.subsidies); setTotal(d.total); })
      .finally(() => setLoading(false));
  }, []);

  const deleteSubsidy = async (id: number) => {
    if (!confirm('削除しますか？')) return;
    await fetch(`/api/admin/subsidies/${id}`, { method: 'DELETE' });
    setSubsidies(prev => prev.filter(s => s.id !== id));
  };

  if (loading) return <div className="max-w-5xl mx-auto px-4 py-8 text-gray-500">読み込み中...</div>;

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">補助金管理</h1>
        <span className="text-gray-500 text-sm">全{total}件</span>
      </div>
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 text-gray-600">補助金名</th>
              <th className="text-left px-4 py-3 text-gray-600">地域</th>
              <th className="text-left px-4 py-3 text-gray-600">カテゴリ</th>
              <th className="text-left px-4 py-3 text-gray-600">ステータス</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {subsidies.map(s => (
              <tr key={s.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium text-gray-800 max-w-xs truncate">{s.title}</td>
                <td className="px-4 py-3 text-gray-500">{s.isNational ? '全国' : s.municipality?.name || '-'}</td>
                <td className="px-4 py-3 text-gray-500">{s.category?.name || '-'}</td>
                <td className="px-4 py-3">
                  <span className={`text-xs px-2 py-1 rounded-full ${s.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : s.status === 'UPCOMING' ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-600'}`}>
                    {s.status === 'ACTIVE' ? '受付中' : s.status === 'UPCOMING' ? '近日' : '終了'}
                  </span>
                </td>
                <td className="px-4 py-3 text-right">
                  <button onClick={() => deleteSubsidy(s.id)} className="text-red-500 hover:text-red-700 text-xs">削除</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
